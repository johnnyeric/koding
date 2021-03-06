package main

import (
	"sync"
)

func main() {
	log.Notice("Started RollbarFeeder")

	var wg sync.WaitGroup

	// NOTE: need to add wg.Add() outside goroutine for some reason
	wg.Add(2)

	go func() {
		defer wg.Done()

		var err = importItemsFromRollbarToDb()
		if err != nil {
			log.Error("Currying items from Rollbar to db: %v", err)
		}
	}()

	go func() {
		defer wg.Done()

		var err = importDeploysFromRollbarToDb()
		if err != nil {
			log.Error("Currying deploys from Rollbar to db: %v", err)
		}
	}()

	wg.Wait()

	var err = checkForDeployAnamolies()
	if err != nil {
		log.Error("Checking for deploy anamolies: %v", err)
	}

	log.Notice("RollbarFeeder ended....applause.")
}
