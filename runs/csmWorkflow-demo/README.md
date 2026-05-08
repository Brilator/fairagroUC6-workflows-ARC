
## Draw workflow from CWL file

```bash
cwltool --print-dot run.cwl | dot -Tsvg > run.svg
```

![run.cwl](run.svg)