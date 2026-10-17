class ClaudeClone < Formula
  desc "Create an isolated second copy of Claude Desktop with a separate account"
  homepage "https://github.com/haric655/homebrew-claude-clone"
  url "https://github.com/haric655/homebrew-claude-clone.git",
      tag:      "v1.0.0",
      revision: "47e18db9ead52eb540bb427ac2fab11e9dee292b"
  license "MIT"
  head "https://github.com/haric655/homebrew-claude-clone.git", branch: "main"

  depends_on :macos

  def install
    bin.install "claude-clone.sh" => "claude-clone"
  end

  test do
    assert_match "claude-clone #{version}", shell_output("#{bin}/claude-clone --version")
  end
end
