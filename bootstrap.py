#!/usr/bin/env python
from pathlib import Path
Path(".bootstrap").mkdir(parents=True, exist_ok=True)
__import__('urllib', fromlist=['request']).request.urlretrieve("https://bootstrap.pypa.io/virtualenv.pyz", ".bootstrap/virtualenv.pyz")
