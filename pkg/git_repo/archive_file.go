package git_repo

import (
	"fmt"
	"path/filepath"

	"github.com/flant/werf/pkg/true_git"
	"github.com/flant/werf/pkg/werf"
	uuid "github.com/satori/go.uuid"
)

type ArchiveFile struct {
	FilePath   string
	Descriptor *true_git.ArchiveDescriptor
}

func NewTmpArchiveFile() *ArchiveFile {
	path := filepath.Join(werf.GetTmpDir(), fmt.Sprintf("werf-%s.archive.tar", uuid.NewV4().String()))
	return &ArchiveFile{FilePath: path}
}

func (a *ArchiveFile) GetFilePath() string {
	return a.FilePath
}

func (a *ArchiveFile) RenameFile(newPath string) error {
	if err := renameFile(a.FilePath, newPath); err != nil {
		return err
	}

	a.FilePath = newPath

	return nil
}

func (a *ArchiveFile) GetType() ArchiveType {
	return ArchiveType(a.Descriptor.Type)
}

func (a *ArchiveFile) IsEmpty() bool {
	return a.Descriptor.IsEmpty
}
