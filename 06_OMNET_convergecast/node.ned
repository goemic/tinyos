/* ASSIGNMENT06
 *
 * @author: Lothar Rubusch
 * @email: L.Rubusch@gmx.ch
 * @date: 2013-Apr-27
 */

// TODO name
simple Txc
{
gates:
        output out;
        input in1;
        input in2;
        input in3;
}

// one outgate (parent) and three in gates (children)
network node
{
submodules:
parent: Txc;
child1: Txc;
child2: Txc;
child3: Txc;

connections:
        child1.out --> { delay = 1000ms; } --> parent.in1;
        child2.out --> { delay = 1000ms; } --> parent.in2;
        child3.out --> { delay = 1000ms; } --> parent.in3;
}
