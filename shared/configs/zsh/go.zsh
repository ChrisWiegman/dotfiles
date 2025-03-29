# Installs the specified Go version for easier development
function gover() {
  go install golang.org/dl/go"$@"@latest
  go"$@" download
}

# Configure GoLang
export GOPATH="$HOME/.go"

# Update system path
export PATH="$GOPATH/bin:$PATH"