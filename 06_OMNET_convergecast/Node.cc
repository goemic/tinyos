//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/.
// 

#include "Node.h"

Define_Module(Node);

Node::Node() {
    // just a series of packets
    counter = 10;
    event = childmsg = NULL;
}

Node::~Node() {
    cancelAndDelete(event);
    cancelAndDelete(childmsg);
}

void Node::initialize()
{
    WATCH( counter );
    event = new cMessage("event");
    scheduleAt(1.0, event);
}

void Node::handleMessage(cMessage *msg)
{
    if( msg == event)
    {
        counter--;
        if(0 == counter){
            EV << getName() << "'s counter reached zero\n";
            delete msg;
            return;
        }

        EV << "send Message.\n";
        childmsg = new cMessage("out");
        scheduleAt(simTime()+1.0, childmsg);

        event = new cMessage("loop");
        scheduleAt(simTime()+1.0, event);
    }else{
        forwardMessage(msg);
    }
}

void Node::forwardMessage( cMessage *msg)
{
    int n = gateSize("out");
    int k = intuniform(0,n-1);

    EV << "Forwarding message " << msg << " on port out[" << k << "]\n";
    send(msg, "out", k);
}
