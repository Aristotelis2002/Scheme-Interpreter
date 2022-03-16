# Interpreter of Scheme written on Scheme
### Introduction
The project is a REPL-based interpreter of the programming language Scheme. It supports most of the simple main functions that come with R5RS and are frequently used. It also supports some of the special-form functions and environment expansion with the use of "define". The way the interpreter is written allows very easily to be "upgraded" (adding more functionality to it). The interpreter is definitely not a basic one, like the ones which only support the lambda function. It also isn't very advanced one because it doesn't support the "creation" of functions which are of a special-form.  
### How to use
The function that interprets is called "interpret". It needs a symbol/symbols as an argument. Here is an example:  
<a href="https://ibb.co/9WSLHsz"><img src="https://i.ibb.co/sqzG9yk/example.png" alt="example" border="0"></a>  
The interpreter allows multiple instructions to be given as input, they will be interpretered successively. A function has to be surrounded in brackets for it to be interpreted as one. The interpreter works exactly as the REPL of Scheme. If we have a variable "x" with the value 5, if we just give '(x) as input, it will interpret it as a symbol and it will search for it in the main environment, if it exists it will return its actual value (which is the same as interpreting it). An extra functionality that the interpreter has is the ability to return multiple results. This is implemented underneath with the help of the function "values" which is from R5RS.  

### Implementation/Documentation of the code  
#### Structure of code
The code is divided in three main parts. The first is the implementation of "pattern matching" which is used a lot in the final section(the main body of the function "interpret"). Second part is the implementation of the environment and the definitions of special-form functions. The third section of the code is the implementation of the function "interpret", which is the most essential part of the project.  
#### First section - pattern matching
Most of the implemetation of the pattern matching comes from this source:  
https://raw.githubusercontent.com/webyrd/quines/master/pmatch.scm   
Some parts of the pattern matching have been removed for the sake of simplicity. The parts which were cut are for reporting errors and different type of errors which wasn't needed for our project. For a further and more detailed explanantion, I suggest reading the documentation of "pmatch".  
The way pattern matching is used in this project is, the function interpret recieves an input and with the use of pattern matching we match what type of input was given to us. The pattern matching can be replaced with the use of "cond" which is from r5rs.  
#### Second section - the environment
The environment is created with the use of a dictionary (the structure of data). It is very easy to shrink or expand the environment. A big portion of this section of code is filled with the calling of the function "env-bind!". This instruction adds an element to the environment with a key, in our case it adds a function from r5rs into the environment with a key which is the name of function. In that way we expanded the environment of the interpreter and now the newly added function from r5rs will be succefully interpreted(unless it is a special-form one). The other part of this section is the implementation of the most frequently used special-form functions.
#### Third section - the body of interpret/evalo
The function "interpret" calls the function "evalo", passes the input and also gives "env" as an argument. "Env" is the main environment which we discussed in the second section.  
The body of "evalo" is made up of pattern-matching in which we chose the right way to interpret the code. Because functions in Scheme can cause different effects, that's why the functions are grouped in different categories -> "special-forms", "environment-expansioners", "non-applicable", "applicable" and "lambda".  
Special-forms are "and","cond","or" and other which can take inf amount of arguments.  
Environment-expansioners are "define" and "set".
Applicable functions are the ones which can be applied to a set/group of variables using the function "apply" from r5rs. It's trivial what "non-applicable" is.  
The way "lambda" works can be understood from here https://www.lvguowei.me/post/the-most-beautiful-program-ever-written/   
This website has a great documentation on interpreting lambda.

