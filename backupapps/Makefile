

dupimg:
	docker build -t dupimg .



demo: dupimg
	docker run -d -it --name demo_mybackup dupimg
	docker exec demo_mybackup /workspace/demo/demo_setup.sh


.PHONY: clean
clean:
	docker rmi -f dupimg 2> /dev/null
