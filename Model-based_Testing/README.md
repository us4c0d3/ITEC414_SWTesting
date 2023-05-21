# Assignment: Model-based Test Generation

## Functional Requirements: Microwave controller

* 전원을 켜면 시간을 디스플레이하고 사용자의 입력을 기다리며 대기한다
    * 문이 열려 있는 상태에서는 전원이 켜지지 않는다

* 전자레인지 power 의 강도는 Full, 과 Half 두가지 옵션이 있다
    * Full power = 600
    * Half power = 300

* 사용자는 power 의 강도를 선택한 후, 작동 시간을 초 단위로 지정할 수 있다.
    * 작동 시간 지정 범위는 1 초에서 60 초 사이로 가정한다

* Power 강도와 작동시간이 지정되었고 문이 닫혀 있으면 작동 버튼이 활성화된다.
* 활성화된 작동 버튼을 누르면, 지정된 강도로 지정된 시간동안 작동한다
    * 활성화된 상태에서 5 초이상 버튼을 누르지 않으면 power 강도와 작동시간 설정이 모두 초기화된다.

* 작동 중 문이 열리면 즉시 작동을 중단하고 알람을 울린다
* 작동이 끝나면 power 강도와 작동시간 설정을 초기화 하고 작동 끝을 알리는 알람을 울린다


## To Do

1. Model the requirements in Finite State Machine

2. Write a NuSMV model from the FSM
    a. The model must satisfy the following properties
        i. 문이 열려있을 때에는 결코 작동되지 않는다
        ii. Full power 로 작동이 시작되면 끝났을 때에도 Full power 로 끝난다
        iii. Half power 로 작동이 시간되면 끝났을 때에도 half power 로 끝난다

3. Generate test cases from the NuSMV using transition coverage criteria


## Submit

1. FSM model (Graphical)

2. NuSMV model (with LTL properties for 100% transition coverage)

3. Test cases and coverage analysis report

4. Proof that your model satisfies essential properties.



### Due: 2023.05.22 1pm





---





# Report

## 1. FSM model (Graphical)

<img src="./Microwave_FSM.png">

## 2. NuSMV model (with LTL properties for 100% transition coverage)

```
-- Microwave.smv
MODULE main
  VAR
    state: {Initial, Waiting, PowerSelected, TimeSelected, Enabled, Cooking, Alarm, Final};
    event: {NONE, On, Off, OpenDoor, CloseDoor, SetPowerFull, SetPowerHalf, SetTime, PressButton, Complete};
    power: {300, 600};
    door: {Closed, Opened};
    time: 0..60;
    counter: 0..6;

  DEFINE
    Full:= 600;
    Half:= 300;

  ASSIGN
    init(counter):= 0;
    init(time):= 0;
    init(state):= Initial;
    init(event):= NONE;

    next(state):= case
        state = Initial & door = Closed & event = On    : Waiting;
        state = Waiting & event = SetPowerFull  : PowerSelected;
        state = Waiting & event = SetPowerHalf  : PowerSelected;
        state = PowerSelected & event = SetTime : TimeSelected;
        state = TimeSelected & door = Closed & time > 0 : Enabled;
        state = Enabled & door = Closed & time > 0 & event = PressButton    : Cooking;
        state = Enabled & counter >= 5  : Waiting;
        state = Cooking & time = 0 & door = Closed  : Alarm;
        state = Cooking & event = OpenDoor & time > 0   : Alarm;
        state = Alarm & time > 0 & event = CloseDoor    : Cooking;
        state = Alarm & time = 0    : Final;
        TRUE                : state;
    esac;

    next(power):= case
        state = Waiting & event = SetPowerFull  : Full;
        state = Waiting & event = SetPowerHalf  : Half;
        state = Enabled & counter >= 5          : {300, 600};
        TRUE                                    : power;
        esac;

    next(time):= case
        state = Initial & event = On & door = Closed    : 0;
        state = PowerSelected & event = SetTime         : 1..60;
        state = Enabled & counter >= 5                  : 0;
        state = Cooking & time > 0                      : time -1;
        TRUE                                            : time;
    esac;

    next(counter):= case
        counter +1 > 5                                  : counter;
        state = Initial & event = On & door = Closed    : 0;
        state = TimeSelected & door = Closed & time > 0 : 0;
        state = Enabled & counter < 5                   : counter +1;
        TRUE                                            : counter;
    esac;

    next(door):= case
        event = OpenDoor    : Opened;
        event = CloseDoor   : Closed;
        TRUE                : door;
    esac;


-- state coverage criteria
LTLSPEC G(! F (state = Initial))
LTLSPEC G(! F (state = Waiting))
LTLSPEC G(! F (state = PowerSelected))
LTLSPEC G(! F (state = TimeSelected))
LTLSPEC G(! F (state = Enabled))
LTLSPEC G(! F (state = Cooking))
LTLSPEC G(! F (state = Alarm))
LTLSPEC G(! F (state = Final))


-- transition coverage criteria (need to analysis)
LTLSPEC G((state = Initial) -> (! F (state = Waiting)))
LTLSPEC G((state = Waiting) -> (! F (state = PowerSelected & power = Full)))
LTLSPEC G((state = Waiting) -> (! F (state = PowerSelected & power = Half)))
LTLSPEC G((state = PowerSelected) -> (! F (state = TimeSelected)))
LTLSPEC G((state = TimeSelected) -> (! F (state = Enabled)))
LTLSPEC G((state = Enabled) -> (! F (state = Waiting)))
LTLSPEC G((state = Enabled) -> (! F (state = Cooking)))
LTLSPEC G((state = Cooking) -> (! F (state = Alarm & time > 0 & door = Opened)))
LTLSPEC G((state = Cooking) -> (! F (state = Alarm & time = 0 & door = Closed)))
LTLSPEC G((state = Alarm) -> (! F (state = Cooking)))
LTLSPEC G((state = Alarm) -> (! F (state = Final)))


-- 4. proof that the model satisfies essential properties
-- i. It never works(cooks) when the door is open
LTLSPEC G(state != Cooking | door != Opened)
-- ii. When Cooking state starts in Full power, it ends in Full power
LTLSPEC G((state = Cooking & power = Full) -> (state = Final -> power = Full))
-- iii. When Cooking state starts in Half power, it ends in Half power
LTLSPEC G((state = Cooking & power = Half) -> (state = Final -> power = Half))
```

이 코드는 파일 별도 첨부하였습니다.



## 3. Test cases and coverage analysis report

### LTL specs from transition coverage criteria

```
008 : G (state = Initial -> !( F state = Waiting)) 
  [LTL            False          9      N/A]
009 : G (state = Waiting -> !( F (state = PowerSelected & power = Full))) 
  [LTL            False          18     N/A]
010 : G (state = Waiting -> !( F (state = PowerSelected & power = Half))) 
  [LTL            False          19     N/A]
011 : G (state = PowerSelected -> !( F state = TimeSelected)) 
  [LTL            False          10     N/A]
012 : G (state = TimeSelected -> !( F state = Enabled)) 
  [LTL            False          11     N/A]
013 : G (state = Enabled -> !( F state = Waiting)) 
  [LTL            False          12     N/A]
014 : G (state = Enabled -> !( F state = Cooking)) 
  [LTL            False          13     N/A]
015 : G (state = Cooking -> !( F ((state = Alarm & time > 0) & door = Opened))) 
  [LTL            False          14     N/A]
016 : G (state = Cooking -> !( F ((state = Alarm & time = 0) & door = Closed))) 
  [LTL            False          15     N/A]
017 : G (state = Alarm -> !( F state = Cooking)) 
  [LTL            False          16     N/A]
018 : G (state = Alarm -> !( F state = Final)) 
  [LTL            False          17     N/A]
```

 이후 `Counterexample`분석은 상기 인덱스 기준으로 분석



### Analysis

#### 008 : G (state = Initial -> !( F state = Waiting))

```
008 : G (state = Initial -> !( F state = Waiting)) 
  [LTL            False          9      N/A]
```

```
-- specification  G (state = Initial -> !( F state = Waiting))  is false
-- as demonstrated by the following execution sequence
Trace Description: LTL Counterexample 
Trace Type: Counterexample 
  -> State: 9.1 <-
    state = Initial
    event = NONE
    power = 300
    door = Closed
    time = 0
    counter = 0
    Half = 300
    Full = 600
  -> State: 9.2 <-
    event = On
  -- Loop starts here
  -> State: 9.3 <-
    state = Waiting
    event = NONE
  -- Loop starts here
  -> State: 9.4 <-
  -> State: 9.5 <-
```





#### 009 : G (state = Waiting -> !( F (state = PowerSelected & power = Full)))

```
009 : G (state = Waiting -> !( F (state = PowerSelected & power = Full))) 
  [LTL            False          18     N/A]
```

```
-- specification  G (state = Waiting -> !( F (state = PowerSelected & power = Full)))  is false
-- as demonstrated by the following execution sequence
Trace Description: LTL Counterexample 
Trace Type: Counterexample 
  -> State: 18.1 <-
    state = Initial
    event = NONE
    power = 300
    door = Closed
    time = 0
    counter = 0
    Half = 300
    Full = 600
  -> State: 18.2 <-
    event = On
  -> State: 18.3 <-
    state = Waiting
    event = NONE
  -> State: 18.4 <-
    event = SetPowerFull
  -> State: 18.5 <-
    state = PowerSelected
    event = NONE
    power = 600
  -> State: 18.6 <-
  -> State: 18.7 <-
    event = SetTime
  -> State: 18.8 <-
    state = TimeSelected
    time = 1
  -> State: 18.9 <-
    state = Enabled
  -> State: 18.10 <-
    counter = 1
  -> State: 18.11 <-
    counter = 2
  -> State: 18.12 <-
    counter = 3
  -> State: 18.13 <-
    counter = 4
  -> State: 18.14 <-
    counter = 5
  -> State: 18.15 <-
    state = Waiting
    event = NONE
    power = 300
    time = 0
  -> State: 18.16 <-
    event = SetPowerFull
  -- Loop starts here
  -> State: 18.17 <-
    state = PowerSelected
    event = NONE
    power = 600
  -- Loop starts here
  -> State: 18.18 <-
  -> State: 18.19 <-
    event = SetTime
  -> State: 18.20 <-
    state = TimeSelected
    time = 1
  -> State: 18.21 <-
    state = Enabled
  -> State: 18.22 <-
    state = Waiting
    event = NONE
    power = 300
    time = 0
  -> State: 18.23 <-
    event = SetPowerFull
  -- Loop starts here
  -> State: 18.24 <-
    state = PowerSelected
    event = NONE
    power = 600
  -> State: 18.25 <-
```





#### 010 : G (state = Waiting -> !( F (state = PowerSelected & power = Half)))

```
010 : G (state = Waiting -> !( F (state = PowerSelected & power = Half))) 
  [LTL            False          19     N/A]
```

```
-- specification  G (state = Waiting -> !( F (state = PowerSelected & power = Half)))  is false
-- as demonstrated by the following execution sequence
Trace Description: LTL Counterexample 
Trace Type: Counterexample 
  -> State: 19.1 <-
    state = Initial
    event = NONE
    power = 300
    door = Closed
    time = 0
    counter = 0
    Half = 300
    Full = 600
  -> State: 19.2 <-
    event = On
  -> State: 19.3 <-
    state = Waiting
    event = NONE
  -> State: 19.4 <-
    event = SetPowerHalf
  -> State: 19.5 <-
    state = PowerSelected
    event = NONE
  -> State: 19.6 <-
  -> State: 19.7 <-
    event = SetTime
  -> State: 19.8 <-
    state = TimeSelected
    time = 1
  -> State: 19.9 <-
    state = Enabled
  -> State: 19.10 <-
    counter = 1
  -> State: 19.11 <-
    counter = 2
  -> State: 19.12 <-
    counter = 3
  -> State: 19.13 <-
    counter = 4
  -> State: 19.14 <-
    counter = 5
  -> State: 19.15 <-
    state = Waiting
    event = NONE
    time = 0
  -> State: 19.16 <-
    event = SetPowerHalf
  -- Loop starts here
  -> State: 19.17 <-
    state = PowerSelected
    event = NONE
  -- Loop starts here
  -> State: 19.18 <-
  -> State: 19.19 <-
    event = SetTime
  -> State: 19.20 <-
    state = TimeSelected
    time = 1
  -> State: 19.21 <-
    state = Enabled
  -> State: 19.22 <-
    state = Waiting
    event = NONE
    time = 0
  -> State: 19.23 <-
    event = SetPowerHalf
  -- Loop starts here
  -> State: 19.24 <-
    state = PowerSelected
    event = NONE
  -> State: 19.25 <-
```





#### 011 : G (state = PowerSelected -> !( F state = TimeSelected))

```
011 : G (state = PowerSelected -> !( F state = TimeSelected)) 
  [LTL            False          10     N/A]
```

```
-- specification  G (state = PowerSelected -> !( F state = TimeSelected))  is false
-- as demonstrated by the following execution sequence
Trace Description: LTL Counterexample 
Trace Type: Counterexample 
  -> State: 10.1 <-
    state = Initial
    event = NONE
    power = 300
    door = Closed
    time = 0
    counter = 0
    Half = 300
    Full = 600
  -> State: 10.2 <-
    event = On
  -> State: 10.3 <-
    state = Waiting
    event = SetPowerHalf
  -> State: 10.4 <-
    state = PowerSelected
    event = NONE
  -> State: 10.5 <-
    event = SetTime
  -> State: 10.6 <-
    state = TimeSelected
    event = NONE
    time = 1
  -> State: 10.7 <-
    state = Enabled
    event = On
  -> State: 10.8 <-
    event = SetTime
    counter = 1
  -> State: 10.9 <-
    counter = 2
  -> State: 10.10 <-
    counter = 3
  -> State: 10.11 <-
    counter = 4
  -> State: 10.12 <-
    counter = 5
  -> State: 10.13 <-
    state = Waiting
    event = SetPowerHalf
    time = 0
  -> State: 10.14 <-
    state = PowerSelected
    event = NONE
  -> State: 10.15 <-
    event = SetTime
  -> State: 10.16 <-
    state = TimeSelected
    event = NONE
    time = 1
  -- Loop starts here
  -> State: 10.17 <-
    state = Enabled
    event = On
  -> State: 10.18 <-
    state = Waiting
    event = SetPowerHalf
    time = 0
  -> State: 10.19 <-
    state = PowerSelected
    event = NONE
  -> State: 10.20 <-
    event = SetTime
  -> State: 10.21 <-
    state = TimeSelected
    event = NONE
    time = 1
  -> State: 10.22 <-
    state = Enabled
    event = On
```





#### 012 : G (state = TimeSelected -> !( F state = Enabled))

```
012 : G (state = TimeSelected -> !( F state = Enabled)) 
  [LTL            False          11     N/A]
```

```
-- specification  G (state = TimeSelected -> !( F state = Enabled))  is false
-- as demonstrated by the following execution sequence
Trace Description: LTL Counterexample 
Trace Type: Counterexample 
  -> State: 11.1 <-
    state = Initial
    event = NONE
    power = 300
    door = Closed
    time = 0
    counter = 0
    Half = 300
    Full = 600
  -> State: 11.2 <-
    event = On
  -> State: 11.3 <-
    state = Waiting
    event = SetPowerHalf
  -> State: 11.4 <-
    state = PowerSelected
    event = SetTime
  -> State: 11.5 <-
    state = TimeSelected
    event = NONE
    time = 1
  -> State: 11.6 <-
    state = Enabled
    event = On
  -> State: 11.7 <-
    counter = 1
  -> State: 11.8 <-
    counter = 2
  -> State: 11.9 <-
    counter = 3
  -> State: 11.10 <-
    counter = 4
  -> State: 11.11 <-
    event = NONE
    counter = 5
  -- Loop starts here
  -> State: 11.12 <-
    state = Waiting
    time = 0
  -> State: 11.13 <-
```





#### 013 : G (state = Enabled -> !( F state = Waiting))

```
013 : G (state = Enabled -> !( F state = Waiting)) 
  [LTL            False          12     N/A]
```

```
-- specification  G (state = Enabled -> !( F state = Waiting))  is false
-- as demonstrated by the following execution sequence
Trace Description: LTL Counterexample 
Trace Type: Counterexample 
  -> State: 12.1 <-
    state = Initial
    event = NONE
    power = 300
    door = Closed
    time = 0
    counter = 0
    Half = 300
    Full = 600
  -> State: 12.2 <-
    event = On
  -> State: 12.3 <-
    state = Waiting
    event = SetPowerHalf
  -> State: 12.4 <-
    state = PowerSelected
    event = SetTime
  -> State: 12.5 <-
    state = TimeSelected
    time = 1
  -> State: 12.6 <-
    state = Enabled
    event = On
  -> State: 12.7 <-
    event = SetTime
    counter = 1
  -> State: 12.8 <-
    counter = 2
  -> State: 12.9 <-
    counter = 3
  -> State: 12.10 <-
    counter = 4
  -> State: 12.11 <-
    counter = 5
  -> State: 12.12 <-
    state = Waiting
    event = NONE
    time = 0
  -> State: 12.13 <-
  -> State: 12.14 <-
    event = SetPowerHalf
  -> State: 12.15 <-
    state = PowerSelected
    event = SetTime
  -> State: 12.16 <-
    state = TimeSelected
    time = 1
  -> State: 12.17 <-
    state = Enabled
    event = On
  -> State: 12.18 <-
    state = Waiting
    event = OpenDoor
    time = 0
  -- Loop starts here
  -> State: 12.19 <-
    door = Opened
  -> State: 12.20 <-
```





#### 014 : G (state = Enabled -> !( F state = Cooking))

```
014 : G (state = Enabled -> !( F state = Cooking)) 
  [LTL            False          13     N/A]
```

```
-- specification  G (state = Enabled -> !( F state = Cooking))  is false
-- as demonstrated by the following execution sequence
Trace Description: LTL Counterexample 
Trace Type: Counterexample 
  -> State: 13.1 <-
    state = Initial
    event = NONE
    power = 300
    door = Closed
    time = 0
    counter = 0
    Half = 300
    Full = 600
  -> State: 13.2 <-
    event = On
  -> State: 13.3 <-
    state = Waiting
    event = SetPowerHalf
  -> State: 13.4 <-
    state = PowerSelected
    event = SetTime
  -> State: 13.5 <-
    state = TimeSelected
    time = 1
  -> State: 13.6 <-
    state = Enabled
    event = On
  -> State: 13.7 <-
    event = PressButton
    counter = 1
  -> State: 13.8 <-
    state = Cooking
    event = SetTime
    counter = 2
  -> State: 13.9 <-
    event = NONE
    time = 0
  -> State: 13.10 <-
    state = Alarm
  -- Loop starts here
  -> State: 13.11 <-
    state = Final
  -> State: 13.12 <-
```





#### 015 : G (state = Cooking -> !( F ((state = Alarm & time > 0) & door = Opened)))

```
015 : G (state = Cooking -> !( F ((state = Alarm & time > 0) & door = Opened))) 
  [LTL            False          14     N/A]
```

```
-- specification  G (state = Cooking -> !( F ((state = Alarm & time > 0) & door = Opened)))  is false
-- as demonstrated by the following execution sequence
Trace Description: LTL Counterexample 
Trace Type: Counterexample 
  -> State: 14.1 <-
    state = Initial
    event = NONE
    power = 300
    door = Closed
    time = 0
    counter = 0
    Half = 300
    Full = 600
  -> State: 14.2 <-
    event = On
  -> State: 14.3 <-
    state = Waiting
    event = SetPowerHalf
  -> State: 14.4 <-
    state = PowerSelected
    event = SetTime
  -> State: 14.5 <-
    state = TimeSelected
    time = 3
  -> State: 14.6 <-
    state = Enabled
    event = PressButton
  -> State: 14.7 <-
    state = Cooking
    event = NONE
    counter = 1
  -> State: 14.8 <-
    event = OpenDoor
    time = 2
  -- Loop starts here
  -> State: 14.9 <-
    state = Alarm
    event = On
    door = Opened
    time = 1
  -- Loop starts here
  -> State: 14.10 <-
  -> State: 14.11 <-
```





#### 016 : G (state = Cooking -> !( F ((state = Alarm & time = 0) & door = Closed)))

```
016 : G (state = Cooking -> !( F ((state = Alarm & time = 0) & door = Closed))) 
  [LTL            False          15     N/A]
```

```
-- specification  G (state = Cooking -> !( F ((state = Alarm & time = 0) & door = Closed)))  is false
-- as demonstrated by the following execution sequence
Trace Description: LTL Counterexample 
Trace Type: Counterexample 
  -> State: 15.1 <-
    state = Initial
    event = NONE
    power = 300
    door = Closed
    time = 0
    counter = 0
    Half = 300
    Full = 600
  -> State: 15.2 <-
    event = On
  -> State: 15.3 <-
    state = Waiting
    event = SetPowerHalf
  -> State: 15.4 <-
    state = PowerSelected
    event = SetTime
  -> State: 15.5 <-
    state = TimeSelected
    time = 1
  -> State: 15.6 <-
    state = Enabled
    event = PressButton
  -> State: 15.7 <-
    state = Cooking
    event = SetTime
    counter = 1
  -> State: 15.8 <-
    time = 0
  -> State: 15.9 <-
    state = Alarm
    event = NONE
  -- Loop starts here
  -> State: 15.10 <-
    state = Final
  -> State: 15.11 <-
```





#### 017 : G (state = Alarm -> !( F state = Cooking))

```
017 : G (state = Alarm -> !( F state = Cooking)) 
  [LTL            False          16     N/A]
```

```
-- specification  G (state = Alarm -> !( F state = Cooking))  is false
-- as demonstrated by the following execution sequence
Trace Description: LTL Counterexample 
Trace Type: Counterexample 
  -> State: 16.1 <-
    state = Initial
    event = NONE
    power = 300
    door = Closed
    time = 0
    counter = 0
    Half = 300
    Full = 600
  -> State: 16.2 <-
    event = On
  -> State: 16.3 <-
    state = Waiting
    event = SetPowerHalf
  -> State: 16.4 <-
    state = PowerSelected
    event = SetTime
  -> State: 16.5 <-
    state = TimeSelected
    time = 2
  -> State: 16.6 <-
    state = Enabled
    event = PressButton
  -> State: 16.7 <-
    state = Cooking
    event = OpenDoor
    counter = 1
  -> State: 16.8 <-
    state = Alarm
    event = On
    door = Opened
    time = 1
  -> State: 16.9 <-
    event = CloseDoor
  -> State: 16.10 <-
    state = Cooking
    event = SetTime
    door = Closed
  -> State: 16.11 <-
    event = NONE
    time = 0
  -> State: 16.12 <-
    state = Alarm
  -- Loop starts here
  -> State: 16.13 <-
    state = Final
  -> State: 16.14 <-
```





#### 018 : G (state = Alarm -> !( F state = Final))

```
018 : G (state = Alarm -> !( F state = Final)) 
  [LTL            False          17     N/A]
```

```
-- specification  G (state = Alarm -> !( F state = Final))  is false
-- as demonstrated by the following execution sequence
Trace Description: LTL Counterexample 
Trace Type: Counterexample 
  -> State: 17.1 <-
    state = Initial
    event = NONE
    power = 300
    door = Closed
    time = 0
    counter = 0
    Half = 300
    Full = 600
  -> State: 17.2 <-
    event = On
  -> State: 17.3 <-
    state = Waiting
    event = SetPowerHalf
  -> State: 17.4 <-
    state = PowerSelected
    event = SetTime
  -> State: 17.5 <-
    state = TimeSelected
    time = 2
  -> State: 17.6 <-
    state = Enabled
    event = PressButton
  -> State: 17.7 <-
    state = Cooking
    event = OpenDoor
    counter = 1
  -> State: 17.8 <-
    state = Alarm
    event = NONE
    door = Opened
    time = 1
  -> State: 17.9 <-
    event = CloseDoor
  -> State: 17.10 <-
    state = Cooking
    event = OpenDoor
    door = Closed
  -> State: 17.11 <-
    state = Alarm
    event = CloseDoor
    door = Opened
    time = 0
  -- Loop starts here
  -> State: 17.12 <-
    state = Final
    event = NONE
    door = Closed
  -- Loop starts here
  -> State: 17.13 <-
  -> State: 17.14 <-
```





## 4. Proof that your model satisfies essential properties.

### LTL specs from following properties

```
-- 4. proof that the model satisfies essential properties
-- i. It never works(cooks) when the door is open
LTLSPEC G(state != Cooking | door != Opened)
-- ii. When Cooking state starts in Full power, it ends in Full power
LTLSPEC G((state = Cooking & power = Full) -> (state = Final -> power = Full))
-- iii. When Cooking state starts in Half power, it ends in Half power
LTLSPEC G((state = Cooking & power = Half) -> (state = Final -> power = Half))
```



### Results

```
019 : G (state != Cooking | door != Opened) 
  [LTL            True           N/A    N/A]
020 : G ((state = Cooking & power = Full) -> (state = Final -> power = Full)) 
  [LTL            True           N/A    N/A]
021 : G ((state = Cooking & power = Half) -> (state = Final -> power = Half)) 
  [LTL            True           N/A    N/A]
```



