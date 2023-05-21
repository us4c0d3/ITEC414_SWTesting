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

...



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



