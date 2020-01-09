package main

import (
	"fmt"
	"os"
)

// function as a type 
type getEnvValidate func() (string, error)

// vars mapped to each ENV variable for future use
var mode, service, namespace string

// global err var
var err error

// function to validate presence and obtain ENV key
func getEnv(key string) (string, error) {
	value := os.Getenv(key)
	if len(value) == 0 {
		// just to print error before terminating
		fmt.Println("Missing ENV variable:", key)

		// exits at first missing ENV
		return "", fmt.Errorf("ENV %s not found", key)
		/*
		// dumb check to see if we iterate for all described ENVs if error not returned 
		return "", nil 
		*/
	}
	return value, nil
}

// functions sharing same signature as type getEnvValidate
func modeEnv() (string, error) {
  mode, err = getEnv("MODE")
  if err != nil {
    return "", err
  }
  return mode, nil
}

func serviceEnv() (string, error) {
  service, err = getEnv("SERVICE")
  if err != nil {
    return "", err
  }
  return service, nil
}

func namespaceEnv() (string, error) {
  namespace, err = getEnv("NAMESPACE")
  if err != nil {
    return "", err
  }
  return namespace, nil
}

/* add new functions for new ENVs here */

// function taking variadic input & iterating over each fn to execute them
func initVar(f ...getEnvValidate) error{
	for _, fs := range f{
	  _, err := fs()
	  if err != nil{
	    return err
	  }
	}
     return nil
}

func main() {

  // construct a slice of fns needed as part of validation
  getAndValidate := []getEnvValidate{modeEnv,serviceEnv,namespaceEnv}

  // call function to execute the individual fns 
  initVar(getAndValidate...)

 /*
 // Print out in positive case. We have defined this as global vars

 fmt.Println(mode)
 fmt.Println(service)
 fmt.Println(namespace)
 */
}


