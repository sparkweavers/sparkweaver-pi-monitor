import os
import re

PLACEHOLDER = re.compile(r"\$\{(\w+)\}")


def _replace(match):
    return os.environ.get(match.group(1), match.group(0))


def substitute(specs):
    """Replaces every ${VAR} in each spec's headers with the matching environment variable."""
    for spec in specs:
        headers = spec.get("headers")
        if isinstance(headers, str):
            spec["headers"] = PLACEHOLDER.sub(_replace, headers)
    return specs


def unresolved(spec):
    """Names the first ${VAR} still unresolved in a spec's headers, or None."""
    headers = spec.get("headers")
    if isinstance(headers, str):
        match = PLACEHOLDER.search(headers)
        if match:
            return match.group(1)
    return None
