{ lib
, buildPythonPackage
, fetchFromGitHub
, pythonOlder
, unittestCheckHook
}:

buildPythonPackage rec {
  pname = "gitignore-parser";
  version = "0.1.5";
  format = "setuptools";

  disabled = pythonOlder "3.7";

  src = fetchFromGitHub {
    owner = "mherrmann";
    repo = "gitignore_parser";
    rev = "refs/tags/v${version}";
    hash = "sha256-Z2x09XwFDMf6sUoKXJ240abp7zctbVCN4dsoQmWVSn8=";
  };

  nativeCheckInputs = [
    unittestCheckHook
  ];

  pythonImportsCheck = [
    "gitignore_parser"
  ];

  meta = with lib; {
    description = "A spec-compliant gitignore parser";
    homepage = "https://github.com/mherrmann/gitignore_parser";
    changelog = "https://github.com/mherrmann/gitignore_parser/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ fab ];
  };
}
