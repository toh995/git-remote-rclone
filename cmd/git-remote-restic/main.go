package main

import (
	"bufio"
	"fmt"
	"os"
	"os/exec"
	"strings"

	"github.com/go-git/go-git/v5"
	"github.com/go-git/go-git/v5/plumbing"
)

func main() {
	// Expected arguments: git-remote-restic <remote> [<url>]
	// url := os.Args[2]
	// fmt.Println(url)
	// exec.Command("notify-send", url).Run()

	os.Setenv("RESTIC_REPOSITORY", "/tmp/restic")
	os.Setenv("RESTIC_PASSWORD", "foo")

	const decryptedRemoteDir = "/tmp/decrypted"

	// We instantiate a new repository targeting the given path
	os.RemoveAll(decryptedRemoteDir)
	exec.Command("restic", "restore", "latest", "--target", decryptedRemoteDir).Run()
	decryptedRemoteRepo, _ := git.PlainOpen(decryptedRemoteDir)

	scanner := bufio.NewScanner(os.Stdin)
	for scanner.Scan() {
		line := scanner.Text()
		notify(line)

		switch split := strings.Split(line, " "); split[0] {
		case "capabilities":
			fmt.Println("fetch")
			fmt.Println("")
		case "list":
			refs, _ := decryptedRemoteRepo.References()
			refs.ForEach(func(ref *plumbing.Reference) error {
				if ref.Type() == plumbing.HashReference {
					notify(ref.String())
					fmt.Println(ref)
				}
				return nil
			})
			fmt.Println("")
		case "fetch":
			fetches := []string{line}
			for scanner.Scan() {
				innerLine := scanner.Text()
				if strings.HasPrefix(innerLine, "fetch") {
					_ = append(fetches, innerLine)
					continue
				}
				break
			}
			shas := make([]string, len(fetches))
			for _, fetch := range fetches {
				sha := strings.Split(fetch, " ")[1]
				_ = append(shas, sha)
			}
		}
	}
}

func notify(s string) {
	exec.Command("notify-send", s).Run()
}
