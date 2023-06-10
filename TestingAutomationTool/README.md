# Testing Automation Tool

## Index
1. [과제 개요](#과제-개요)
2. [Tool Usage](#my-tool-usage)
3. [Feedback](#feedback)

## 과제 개요
### 1. input

- 단위함수와 테스트 케이스는 각각 다른 파일로 주어진다고 가정 (예: triangle.c triangle_test_cases.txt)

- 테스트 케이스 파일의 첫줄에 테스트할 함수 이름의 원형이 주어진다고 가정 (함수원형 예: int triangle(int a, int b, int c))

- 테스트 케이스 포맷:  (id, input values, expected output value)  구분자는 space

<br>

### 2. output

1. test driver 함수가 정의된 파일  (예: triangle_driver.c)

2. test 수행 script (예: run_test.sh) : 해당 script 를 수행하면 테스트가 수행되고 결과가 별도의 파일로 생성되어야 함

 <br>

### 3. 주의

예제에서 보이고 있는 triangle_driver.c 는 테스트 케이스들을 hardcode 하고 있음. 문제해결시에는 hardcode 금지

(파일에서 읽어서 처리. 과제 채점 시에는 triangle.c 사용하지 않음)

 <br>

### 4. 제출

테스트 자동화 프로그램 코드 (+ shell script)

<br>
 

### 5. 자동화 프로그램이 해야할 일

1. 테스트케이스 파일을 읽어서 test driver 생성

2. 생성된 test driver 를 포함하여 프로그램을 컴파일하고 테스트 실행 후 coverage 를 측정=

3. 테스트 수행 보고서 출력

<br>

---

<br>

## My tool Usage
Usage: ./my_testing_tool.sh <c_code_file> <test_case_file>
<br><br>
실행 시 권한 문제가 발생할 수 있습니다. 그럴 경우에는 다음 명령어로 권한을 부여해주십시오.
```
$ chmod 777 my_testing_tool.sh
```
<br><br>
실행 결과로 `{function_name}_driver.c`, `{function_name}_test_result.txt` 그리고 `gcov`의 결과로 생기는 파일들이 생성됩니다.
<br><br>
테스트 실행 결과 및 `gcov`를 이용한 coverage testing결과는 `{function_name}_test_result.txt`에 출력됩니다.

---

## Feedback

__20/25__

> tc1: driver compile error
