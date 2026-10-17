class ClaudeClone < Formula
  desc "Create an isolated second copy of Claude Desktop with a separate account"
  homepage "https://github.com/haric655/homebrew-tools"
  url "https://github.com/haric655/homebrew-tools.git",
      tag:      "v1.0.0",
      revision: "REPLACE_WITH_COMMIT_SHA"
  license "MIT"
  head "https://github.com/haric655/homebrew-tools.git", branch: "main"

  depends_on :macos

  def install
    bin.install "claude-clone.sh" => "claude-clone"
  end

  test do
    assert_match "claude-clone #{version}", shell_output("#{bin}/claude-clone --version")
  end
end
