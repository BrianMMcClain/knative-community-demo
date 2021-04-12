github-issue-comment-source
===

Knative event source that will track the comments on a GitHub issue and emit a CloudEvent everytime a new one is created

Sample Setup YAML
---

```
apiVersion: sources.knative.dev/v1
kind: ContainerSource
metadata:
  name: github-issue-comment-source
spec:
  template:
    spec:
      containers:
        - image: brianmmcclain/github-issue-comment-source
          name: github-issue-comment-source
          args:
            - --owner=[REPO OWNER]
            - --repo=[REPO NAME]
            - --issue=[ISSUE NUMBER]
            - --interval=90
            - --fromBeginning
          env:
            - name: POD_NAME
              value: "github-issue-comment-source"
            - name: POD_NAMESPACE
              value: "event-test"
  sink:
    ref:
      apiVersion: serving.knative.dev/v1
      kind: Service
      name: event-display
```

Args
---

Using issue #1 in this repository as an example:

- `--owner`: The owner of the GitHub repository (ie. "brianmmcclain")
- `--repo`: The name of the repository (ie. "knative-community-demo")
- `--issue`: The issue number to track (ie. "1")
- `--interval`: (Default: 60) How often (in seconds) to poll the issue for new comments. NOTE: Currently this is an unauthenticated request, meaning you're limited to 60 requests/hour, so ensure this is set to 60 at minimum
- `--fromBeginning`: (Optional) `true` if an event should be emitted for every existing comment, or `false` if an event should only be emitted for new comments