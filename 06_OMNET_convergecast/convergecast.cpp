/* ASSIGNMENT06
 *
 * @author: Lothar Rubusch
 * @email: L.Rubusch@gmx.ch
 * @date: 2013-Apr-27
 */

#include <string.h>
#include <omnetpp.h>

class Txc : public cSimpleModule {
protected:
  // redefine virtual funcs
  virtual void initialize();
  virtual void handleMessage( cMessage *msg );
};

Define_Module( Txc );
void Txc::initialize(){
  //  if( strcmp( ""
  cMessage *msg = new cMessage( "somecontent" );
  send( msg, "out" );
}

void Txc::handleMessage( cMessage *msg ){
  send( msg, "out" );
}
