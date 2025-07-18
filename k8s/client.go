// Copyright © 2021 - 2025 Dell Inc. or its subsidiaries. All Rights Reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//       http://www.apache.org/licenses/LICENSE-2.0
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

package k8s

import (
	"fmt"
	"os"

	"k8s.io/apimachinery/pkg/version"
	"k8s.io/client-go/kubernetes"
	"sigs.k8s.io/controller-runtime/pkg/client/config"

	"go.uber.org/zap"
	"k8s.io/apimachinery/pkg/runtime"
	utilruntime "k8s.io/apimachinery/pkg/util/runtime"
	clientgoscheme "k8s.io/client-go/kubernetes/scheme"
	"k8s.io/client-go/tools/clientcmd"
	ctrlClient "sigs.k8s.io/controller-runtime/pkg/client"
)

// GetClientSetWrapper -
var GetClientSetWrapper = func() (kubernetes.Interface, error) {
	// Get a config to talk to the apiserver
	cfg, err := config.GetConfig()
	if err != nil {
		return nil, err
	}

	clientset, err := kubernetes.NewForConfig(cfg)
	if err != nil {
		return nil, err
	}

	return clientset, nil
}

// GetKubeAPIServerVersion returns version of the k8s/openshift cluster
func GetKubeAPIServerVersion() (*version.Info, error) {
	k8sClientSet, err := GetClientSetWrapper()
	if err != nil {
		return nil, err
	}

	sv, err := k8sClientSet.Discovery().ServerVersion()
	if err != nil {
		return nil, err
	}

	return sv, nil
}

// IsOpenShift - Returns a boolean which indicates if we are running in an OpenShift cluster
func IsOpenShift(log *zap.SugaredLogger) (bool, error) {
	k8sClientSet, err := GetClientSetWrapper()
	if err != nil {
		return false, err
	}

	serverGroups, _, err := k8sClientSet.Discovery().ServerGroupsAndResources()
	if err != nil {
		if log != nil {
			log.Info(fmt.Sprintf("isOpenShift err %v", err))
		}
	}
	if serverGroups == nil {
		return false, fmt.Errorf("serverGroups is nil")
	}

	openshiftAPIGroup := "security.openshift.io"
	for i := 0; i < len(serverGroups); i++ {
		if serverGroups[i].Name == openshiftAPIGroup {
			return true, nil
		}
	}

	return false, nil
}

// NewControllerRuntimeClient will return a new controller runtime client using config
func NewControllerRuntimeClient(data []byte) (ctrlClient.Client, error) {
	restConfig, err := clientcmd.RESTConfigFromKubeConfig(data)
	if err != nil {
		return nil, err
	}

	scheme := runtime.NewScheme()
	utilruntime.Must(clientgoscheme.AddToScheme(scheme))
	return ctrlClient.New(restConfig, ctrlClient.Options{Scheme: scheme})
}

// Unit tests require a kubeconfig that is known and stable between testing environments.
func CreateTempKubeconfig(filepath string) error {
	kubeconfig := `clusters:
- cluster:
    server: https://some.hostname.or.ip:6443
  name: fake-cluster
contexts:
- context:
    cluster: fake-cluster
    user: admin
  name: admin
current-context: admin
preferences: {}
users:
- name: admin`

	return os.WriteFile(filepath, []byte(kubeconfig), 0o600)
}
