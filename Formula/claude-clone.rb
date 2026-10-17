class ClaudeClone < Formula
  desc "Create an isolated second copy of Claude Desktop with a separate account"
  homepage "https://github.com/haric655/homebrew-claude-clone"
  url "https://github.com/haric655/homebrew-claude-clone/archive/refs/tags/v1.0.0.tar.gz"
  sha256 "8606b833bd4888b49756e754841576be763def27a18466fa72139ce5b3699539"
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
