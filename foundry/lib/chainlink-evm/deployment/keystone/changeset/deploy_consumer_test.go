package changeset_test

import (
	"testing"

	"go.uber.org/zap/zapcore"

	"github.com/stretchr/testify/require"

	"github.com/smartcontractkit/chainlink-common/pkg/logger"
	"github.com/smartcontractkit/chainlink-deployments-framework/datastore"

	"github.com/smartcontractkit/chainlink/deployment/environment/memory"
	"github.com/smartcontractkit/chainlink/deployment/keystone/changeset"
)

func TestDeployFeedsConsumer(t *testing.T) {

	t.Parallel()
	lggr := logger.Test(t)
	cfg := memory.MemoryEnvironmentConfig{
		Nodes:  1,
		Chains: 2,
	}
	env := memory.NewMemoryEnvironment(t, lggr, zapcore.DebugLevel, cfg)

	registrySel := env.AllChainSelectors()[0]
	resp, err := changeset.DeployFeedsConsumerV2(env, &changeset.DeployRequestV2{
		ChainSel:  registrySel,
		Qualifier: "my-test-feeds-consumer",
	})
	require.NoError(t, err)
	require.NotNil(t, resp)
	// feeds consumer should be deployed on chain 0
	addrs, err := resp.AddressBook.AddressesForChain(registrySel)
	require.NoError(t, err)
	require.Len(t, addrs, 1)
	require.Len(t, resp.DataStore.Addresses().Filter(datastore.AddressRefByQualifier("my-test-feeds-consumer")), 1, "expected to find 'my-test-feeds-consumer' qualifier")

	// no feeds consumer registry on chain 1
	require.NotEqual(t, registrySel, env.AllChainSelectors()[1])
	oaddrs, _ := resp.AddressBook.AddressesForChain(env.AllChainSelectors()[1])
	require.Empty(t, oaddrs)
}
