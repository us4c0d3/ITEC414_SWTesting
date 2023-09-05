

``` bash
-- simple.smv

MODULE main

  VAR
    request :   boolean;
    state   :   {ready, busy};

  ASSIGN
    init(state) :=  ready;

    next(state) :=  case
        state = ready & request = TRUE  : busy;
        state = busy & !request         : ready;
        TRUE                            : state;
        esac;
    
    next(request)   := !request;


LTLSPEC G (request -> F (state = busy))
LTLSPEC G ((state = busy) -> F (state = ready))
```

![image-20230508135500092](C:\Users\WooseokJang\AppData\Roaming\Typora\typora-user-images\image1.png)





```bash
-- simple.smv
-- more ltlspec

MODULE main

  VAR
    request :   boolean;
    state   :   {ready, busy};

  ASSIGN
    init(state) :=  ready;

    next(state) :=  case
        state = ready & request = TRUE  : busy;
        state = busy & !request         : ready;
        TRUE                            : state;
        esac;
    
    next(request)   := !request;


LTLSPEC G (request -> F (state = busy))
LTLSPEC G ((state = busy) -> F (state = ready))
LTLSPEC G ((! F (state = ready)))
LTLSPEC G ((! F (state = busy)))
LTLSPEC G ((state = ready) -> ! X (state = busy))
LTLSPEC G ((state = busy) -> ! X (state = ready))
```

```bash
Trace Type: Counterexample
  -> State: 1.1 <-
    request = FALSE
    state = ready
  -- Loop starts here
  -> State: 1.2 <-
    request = TRUE
  -> State: 1.3 <-
    request = FALSE
    state = busy
  -> State: 1.4 <-
    request = TRUE
    state = ready
```

* test input: request
* expected output: state
  * request에 따라 내부적으로 변함





```bash
-- simple_1.smv

MODULE main

  VAR
    request :   boolean;
    state   :   {ready, busy};

  ASSIGN
    init(state) :=  ready;

    next(state) :=  case
        state = ready & request = TRUE  : busy;
        state = busy & !request         : ready;
        TRUE                            : state;
        esac;


LTLSPEC G (request -> F (state = busy))
LTLSPEC G ((state = busy) -> F (state = ready))
```

![image-20230508135901047](C:\Users\WooseokJang\AppData\Roaming\Typora\typora-user-images\image2.png)





```bash
-- vendingMachine_initial.smv

MODULE main
  VAR
   state: {Initial, Ready, Inserting, Enabled, Emitting, Returning, Final};
   amount: 0..1500;
   coin : {100, 500}; 
   event: {NONE, On, Off, Insert, Choose, Complete};
   time : 0..11;
  DEFINE
   COST:= 500;

  ASSIGN
    init(amount):= 0;
    init(time):=0;
    init(state):= Initial;
    init(event):= NONE;

    next(state):= case
        state = Initial & event = On   : Ready;
        state = Ready & event = Insert : Inserting;
        state = Ready & event = Off    : Final;
        state = Inserting & amount < 500 & time < 10 : Inserting;
        TRUE                                  : state;
    esac;

    next(amount):= case
        amount + coin > 1500 : amount;
        state = Initial & event = On   : 0;
        state = Ready & event = Insert : amount+coin ;
        state = Inserting & event =Insert &  time < 10 : amount+coin;
        TRUE                                  : amount;
    esac; 
    
    next(time):= case
        time +1 > 10   : time;
        state = Initial & event = On   : 0;
        state = Ready & event = Insert : 0;
        state = Inserting & event = Insert & time < 10 : 0;
        state = Inserting & time < 10 : time +1;
        TRUE                                  : time;
    esac; 

LTLSPEC G(state != Inserting)
LTLSPEC G(amount < 500)
LTLSPEC G(state != Enabled)
LTLSPEC G(state != Emitting)
LTLSPEC G(state != Returning)

```



