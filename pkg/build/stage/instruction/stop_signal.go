package instruction

import (
	"context"

	"github.com/moby/buildkit/frontend/dockerfile/instructions"

	"github.com/werf/werf/pkg/build/stage"
	"github.com/werf/werf/pkg/config"
	"github.com/werf/werf/pkg/container_backend"
	backend_instruction "github.com/werf/werf/pkg/container_backend/instruction"
	"github.com/werf/werf/pkg/dockerfile"
	"github.com/werf/werf/pkg/util"
)

type StopSignal struct {
	*Base[*instructions.StopSignalCommand, *backend_instruction.StopSignal]
}

func NewStopSignal(name stage.StageName, i *dockerfile.DockerfileStageInstruction[*instructions.StopSignalCommand], dependencies []*config.Dependency, hasPrevStage bool, opts *stage.BaseStageOptions) *StopSignal {
	return &StopSignal{Base: NewBase(name, i, backend_instruction.NewStopSignal(i.Data), dependencies, hasPrevStage, opts)}
}

func (stg *StopSignal) GetDependencies(ctx context.Context, c stage.Conveyor, cb container_backend.ContainerBackend, prevImage, prevBuiltImage *stage.StageImage, buildContextArchive container_backend.BuildContextArchiver) (string, error) {
	args, err := stg.getDependencies(ctx, c, cb, prevImage, prevBuiltImage, buildContextArchive, stg)
	if err != nil {
		return "", err
	}

	args = append(args, "Instruction", stg.instruction.Data.Name())
	args = append(args, "Signal", stg.instruction.Data.Signal)
	return util.Sha256Hash(args...), nil
}
