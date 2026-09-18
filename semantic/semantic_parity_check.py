"""Compare C1 serialized variants with the supplied JSON-LD, SHACL and SPARQL.

Requires rdflib and pyshacl. Cryptographic digest recomputation belongs to the
MATLAB runtime validator; SHACL checks only hash field presence and syntax.
"""
import csv
import json
from pathlib import Path

from pyshacl import validate
from rdflib import Graph, Literal, Namespace, RDF, URIRef


ROOT = Path(__file__).resolve().parents[1]
ART = ROOT / "artifacts"
OUT = ROOT / "audit" / "semantic_parity.csv"
CONTEXT = json.loads((ART / "context.jsonld").read_text(encoding="utf-8"))["@context"]
SHAPES = Graph().parse(ART / "shapes.ttl", format="turtle")
CKG = Namespace("https://example.org/ckg#")
NOW = "2026-09-17T12:00:00"


def projected_graph(record):
    # A typed semantic view of the same serialized record, with request context.
    fields = (
        "vehicle_class_id", "cell_id", "artifact_id", "version",
        "creation_time", "expiry_time", "cell_bounds", "uncertainty_bounds",
        "audited_min_margin", "fallback_parent", "integrity_hash",
    )
    doc = {key: record[key] for key in fields if key in record}
    for key in ("cell_bounds", "uncertainty_bounds"):
        if key in doc:
            doc[key] = json.dumps(doc[key], separators=(",", ":"))
    doc.update({"@context": CONTEXT, "@id": "ckg:auditArtifact",
                "@type": "ckg:Artifact", "requested_cell": "C1",
                "validation_time": NOW})
    for key in ("P", "Q", "R"):
        if key in record:
            doc[key] = json.dumps(record[key], separators=(",", ":"))
    graph = Graph().parse(data=json.dumps(doc), format="json-ld")
    subject = URIRef(CKG.auditArtifact)
    for vertex_id in record.get("vertices", {}).get("ids", []):
        graph.add((subject, CKG.admits, URIRef(CKG[str(vertex_id)])))
    return graph


def main():
    runtime_file = ROOT / "results" / "semantic_runtime_cases.csv"
    runtime = {row["case"]: row for row in csv.DictReader(
        runtime_file.open(encoding="utf-8"))}
    cases = ("valid", "stale", "hash", "wrong_cell", "missing")
    rows = []
    for case in cases:
        path = (ART / "C1_artifact.json" if case == "valid"
                else ART / "faults" / f"C1_{case}.json")
        graph = projected_graph(json.loads(path.read_text(encoding="utf-8")))
        conforms, _, _ = validate(graph, shacl_graph=SHAPES, advanced=True)
        vertex_count = len(list(graph.query(
            "PREFIX ckg: <https://example.org/ckg#> "
            "SELECT ?vertex WHERE { ckg:auditArtifact ckg:admits ?vertex }")))
        fallback_count = len(list(graph.query(
            "PREFIX ckg: <https://example.org/ckg#> "
            "SELECT ?fallback WHERE { ckg:auditArtifact ckg:fallsBackTo ?fallback }")))
        if case == "hash":
            scope = "cryptographic_hash_outside_SHACL"
            agreement = "scope_excluded"
        else:
            scope = "represented_predicates"
            agreement = "yes" if conforms == (runtime[case]["matlab_valid"] == "1") else "no"
        rows.append((case, runtime[case]["matlab_valid"],
                     runtime[case]["matlab_reason"], int(conforms),
                     vertex_count, fallback_count, scope, agreement))
    with OUT.open("w", newline="", encoding="utf-8") as stream:
        writer = csv.writer(stream)
        writer.writerow(("case", "matlab_valid", "matlab_reason",
                         "semantic_shacl_valid", "sparql_vertices",
                         "sparql_fallbacks", "scope", "agreement"))
        writer.writerows(rows)
    assert all(row[-1] == "yes" for row in rows if row[0] != "hash")
    assert rows[0][4] == 3 and rows[0][5] == 1
    print(f"Semantic parity: {OUT}")
    for row in rows:
        print(row)


if __name__ == "__main__":
    main()
