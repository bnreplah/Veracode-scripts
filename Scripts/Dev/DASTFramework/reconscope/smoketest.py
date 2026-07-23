import sys
sys.path.insert(0, ".")
from reconscope import (Scanner, ResultStore, parse_selection, normalize_url,
                         load_urls_from_txt, load_urls_from_csv, dedupe_preserve_order)
from pathlib import Path

BASE = "http://127.0.0.1:8765"
urls = [f"{BASE}/normal", f"{BASE}/phperror", f"{BASE}/notfound",
        f"{BASE}/servererror", f"{BASE}/redirect"]

store = ResultStore()
scanner = Scanner(timeout=3, verify=True, max_workers=5)

idxs = store.reserve_indices(len(urls))
tasks = [(lambda i=i, u=u: scanner.probe_initial(i, u)) for i, u in zip(idxs, urls)]
results = scanner.run_bulk(tasks)
store.add_many(results)

print("--- Phase 1 results ---")
for r in store.all():
    print(r.index, r.url, "->", r.status_code, "fp:", r.fingerprints, "err:", [e[0] for e in r.error_signatures])

assert store.all()[0].status_code == 200
normal = [r for r in store.all() if "/normal" in r.url][0]
assert "WordPress" in normal.fingerprints, f"expected WordPress fingerprint, got {normal.fingerprints}"
assert "Apache httpd" in normal.fingerprints, f"expected Apache fingerprint, got {normal.fingerprints}"

phperr = [r for r in store.all() if "/phperror" in r.url][0]
assert phperr.status_code == 200
assert any(lbl == "PHP Fatal Error" for lbl, _ in phperr.error_signatures), phperr.error_signatures

notfound = [r for r in store.all() if "/notfound" in r.url][0]
assert notfound.status_code == 404

srverr = [r for r in store.all() if "/servererror" in r.url][0]
assert srverr.status_code == 500

redir = [r for r in store.all() if "/redirect" in r.url][0]
assert redir.status_code == 200  # requests follows redirects by default
assert redir.final_url and "/normal" in redir.final_url

# --- selection parser ---
sel = parse_selection("status:404", store.all())
assert len(sel) == 1 and sel[0].url.endswith("/notfound")
sel2 = parse_selection("status:2xx", store.all())
assert all(200 <= r.status_code < 300 for r in sel2)
sel3 = parse_selection("1,3", store.all())
assert [r.index for r in sel3] == [1, 3]

# --- filter store ---
errs = store.filter(has_errors=True)
assert len(errs) == 1 and errs[0].url.endswith("/phperror")

# --- secondary iteration with custom headers/payload against /echo ---
echo_url = f"{BASE}/echo"
sec_idx = store.reserve_indices(1)[0]
sec_result = scanner.probe_secondary(sec_idx, echo_url, "POST",
                                      {"X-Custom-Test": "hello", "User-Agent": "reconscope-test"},
                                      "field=value")
store.add_many([sec_result])
print("\n--- Secondary /echo result ---")
print(sec_result.status_code, sec_result.body_snippet)
assert sec_result.status_code == 200
assert "X-Custom-Test" in sec_result.body_snippet or "hello" in sec_result.body_snippet

# --- URL loading from files ---
Path("urls_test.txt").write_text("# comment\nexample.com\nhttp://foo.test\n\n")
loaded_txt = load_urls_from_txt(Path("urls_test.txt"))
assert loaded_txt == ["https://example.com", "http://foo.test"], loaded_txt

Path("urls_test.csv").write_text("url,notes\nexample.com,first\nhttp://bar.test,second\n")
loaded_csv = load_urls_from_csv(Path("urls_test.csv"))
assert loaded_csv == ["https://example.com", "http://bar.test"], loaded_csv

deduped = dedupe_preserve_order(["a", "b", "a", "c", "b"])
assert deduped == ["a", "b", "c"], deduped

# --- export/import round trip ---
store.export_json(Path("results_test.json"))
store2 = ResultStore()
store2.load_json(Path("results_test.json"))
assert len(store2.results) == len(store.results)

store.export_csv(Path("results_test.csv"))
assert Path("results_test.csv").exists()

print("\nALL SMOKE TESTS PASSED")
