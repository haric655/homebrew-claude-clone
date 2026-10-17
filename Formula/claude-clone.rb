class ClaudeClone < Formula
  desc "Create an isolated second copy of Claude Desktop with a separate account"
  homepage "https://github.com/haric655/homebrew-claude-clone"
  url "https://github.com/haric655/homebrew-claude-clone/archive/refs/tags/v1.1.0.tar.gz"
  sha256 "1dbb8975b8f8bd0994c934d6f5fdc638743bb3dd13b89356222d69096fc0d896"
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
