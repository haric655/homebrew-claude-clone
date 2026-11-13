class ClaudeClone < Formula
  desc "Create an isolated second copy of Claude Desktop with a separate account"
  homepage "https://github.com/haric655/homebrew-claude-clone"
  url "https://github.com/haric655/homebrew-claude-clone/archive/refs/tags/v1.2.0.tar.gz"
  sha256 "decf30b96db6324c4bba6f85635e1c656713a517f5c6ff1cd23b9e5c881f1ab1"
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
