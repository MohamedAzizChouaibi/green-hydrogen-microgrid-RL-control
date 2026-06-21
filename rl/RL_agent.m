mdl='GreenHydrogenMicrogrid';
open_system(mdl);
Ts=1;
Tf=100;

blk='GreenHydrogenMicrogrid/Energy storage/RL Agent';
numObs=2;
obsInfo=rlNumericSpec([numObs 1]);
numAct=1;
agent=rlPPOAgent(obsInfo,actInfo);
agent;
actInfo=rlNumericSpec([numAct 1],"LowerLimit",-10,"UpperLimit",10);
greenEnv=rlSimulinkEnv(mdl,blk,obsInfo,actInfo);
