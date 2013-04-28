/* ASSIGNMENT06
 *
 * @author: Lothar Rubusch
 * @email: L.Rubusch@gmx.ch
 * @date: 2013-Apr-27
 */

// TODO

// TODO name
simple Txc
{
gates:
        input in1;
}

// one outgate (parent) and three in gates (children)
network node
{
submodules:
child: Txc;

connections:
        child1.out --> { delay = 1000ms; } --> parent.in1;
}

