//
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU Lesser General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARchildULAR PURPOSE.  See the
// GNU Lesser General Public License for more details.
// 
// You should have received a copy of the GNU Lesser General Public License
// along with this program.  If not, see http://www.gnu.org/licenses/.
// 

// Created: 2013-3-30 for project convergecast

package convergecast;

simple Node
{   
    parameters:
        @display("i=block/routing");
    gates:
        input in[];  // declare in[] and out[] to be vector gates                                                              
        output out[];
}

simple Sink
{
    parameters:
        @display("i=block/routing");
    gates:
        input sinkin[];  // declare in[] and out[] to be vector gates                                                              
        output sinkout[];
}

network Convergecast
{
    submodules:
        child[12]: Node;
        sink: Sink;

    connections:
        child[0].out++ --> {  delay = 1000ms; } --> sink.sinkin++;
        child[3].out++ --> {  delay = 1000ms; } --> child[0].in++;
        child[4].out++ --> {  delay = 1000ms; } --> child[0].in++;
        child[5].out++ --> {  delay = 1000ms; } --> child[0].in++;
        
        child[1].out++ --> {  delay = 1000ms; } --> sink.sinkin++;
        child[6].out++ --> {  delay = 1000ms; } --> child[1].in++;
        child[7].out++ --> {  delay = 1000ms; } --> child[1].in++;
        child[8].out++ --> {  delay = 1000ms; } --> child[1].in++;
        
        child[2].out++ --> {  delay = 1000ms; } --> sink.sinkin++;
		child[9].out++ --> {  delay = 1000ms; } --> child[2].in++;
        child[10].out++ --> {  delay = 1000ms; } --> child[2].in++;
        child[11].out++ --> {  delay = 1000ms; } --> child[2].in++;
}
