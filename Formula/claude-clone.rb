class ClaudeClone < Formula
  desc "Create an isolated second copy of Claude Desktop with a separate account"
  homepage "https://github.com/haric655/homebrew-claude-clone"
  url "https://github.com/haric655/homebrew-claude-clone/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "5cddc921e894b4c82c89d5a9cdc4f69fb36c266b65276b782231e6e855a68946"
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
