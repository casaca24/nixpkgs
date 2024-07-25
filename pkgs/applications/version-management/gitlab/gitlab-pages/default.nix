{ buildGoModule, lib, fetchFromGitLab }:

buildGoModule rec {
  pname = "gitlab-pages";
  version = "17.2.1";

  # nixpkgs-update: no auto update
  src = fetchFromGitLab {
    owner = "gitlab-org";
    repo = "gitlab-pages";
    rev = "v${version}";
    hash = "sha256-4viJD8i+9vVPQISpGB9tZFqCk/LonfcPZy9uYoDu3Qw=";
  };

  vendorHash = "sha256-yNHeM8MExcLwv2Ga4vtBmPFBt/Rj7Gd4QQYDlnAIo+c=";
  subPackages = [ "." ];

  meta = with lib; {
    description = "Daemon used to serve static websites for GitLab users";
    mainProgram = "gitlab-pages";
    homepage = "https://gitlab.com/gitlab-org/gitlab-pages";
    changelog = "https://gitlab.com/gitlab-org/gitlab-pages/-/blob/v${version}/CHANGELOG.md";
    license = licenses.mit;
    maintainers = teams.helsinki-systems.members ++ teams.gitlab.members;
  };
}
