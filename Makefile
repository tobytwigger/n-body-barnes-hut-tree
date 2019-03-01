build:
	python setup.py build_ext -fi

clean:
	rm -r build/ src/*.c src/*.so venv/ analysis/*.c analysis/*.so

install:
	pip install -r requirements.txt

create-environment:
	python3 -m venv venv
