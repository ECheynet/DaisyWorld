function [alphaW,alphaB,T,E] = daisyWorld(t,Irradiance,L,alphaW0,alphaB0,gamma,varargin)
% [alphaW,alphaB,T_global,E] = daisyWorld(t,Irradiance,L,alphaW0,alphaB0,
% gamma,varargin) simulates the time histories of the black and white daisy
% relative population as well as the temperature T of the planet "Daisyworld"
% and the greenhoise effect.
%
%% Input:
% t: time vector. Size: [1xN] array of double
% Irradiance : solar constant at the planet surface. Size: [1xN] array of double
% L: Luminance. Size: [1xN] array of double
% alphaW0: Initial population of white daisies. Size: [1x1] array of double
% alphaB0: Initial population of black daisies. Size: [1x1] array of double
% gamma: Death rates of the daisies. Size: [1x1] array of double
%
% deltaT is a constant that gives the range of temperature (in K) where the daisies can grow
% albedoG is the albedo of the ground between 0 and 1
% albedoW is the albedo of the white daisies between 0 and 1
% albedoB is the albedo of the black daisies between 0 and 1
%% Optional parameter
% albedoW: albedo of the white daisies (default value: 0.8)
% albedoB: albedo of the black daisies (default value: 0.2)
% albedoG: albedo of the ground (default value: 0.5)
% a: emission rate of greenhouse gas  (default value: 1.e-4 day-1)
% b: absorption rate of greenhouse gas  (default value: 1.e-3 day-1)
% c: thermal inertia (or average heat capacity) of the planet (default value: 950 K^-1)
%
%% Output
% alpha_w: Time histories of the white daiy population. Size: [1x1] array of double
% alpha_B:  Time histories of the black daiy population.  Size: [1x1] array of double
% E: Time histories of the greenhouse efect. Size: [1x1] array of double
% T: Time histories of the planetray temperature. Size: [1x1] array of double
%
%% Author: E. Cheynet -- UiB -- last modified: 18-06-2022


%% Inputparseer
p = inputParser();
p.CaseSensitive = false;
p.addOptional('albedoW',0.8);
p.addOptional('albedoB',0.2);
p.addOptional('albedoG',0.5);
p.addOptional('a',1e-4);
p.addOptional('b',1e-3);
p.addOptional('c',950);
p.parse(varargin{:});
albedoW = p.Results.albedoW ;
albedoB = p.Results.albedoB ;
albedoG = p.Results.albedoG ;
a = p.Results.a ;
b = p.Results.b ;
c = p.Results.c;

%% Constant definitions and initial checks

BoltzmannC = 5.67e-8  ; % Botlzmann constant in W/m^2/K^4
if albedoG >albedoW || albedoB >albedoG || albedoB >albedoW
    error('You must choose albedoB < albedoG < albedoW')
end


%% Matrices preallocation and Initial condtions

N = numel(t) ; %  get number of time step
dt = median(diff(t)) ; %  get time step
alphaW = zeros(1,N) ; %  percentage of white  daisies
alphaB = zeros(1,N) ; %  percentage of Black  daisies
T = zeros(1,N) ; %  temperature of the planet
E = zeros(1,N) ; %  Greenhouse effect

alphaW(1) = alphaW0 ; %  get population of white daisies at step ii+1
alphaB(1) = alphaB0 ; %  get population of white daisies at step ii+1
alphaG = 1 - alphaW(1) - alphaB(1) ; %  percentage of ground uncovered by daisies
albedo_tot = albedoG*alphaG + albedoW*alphaW(1) + albedoB*alphaB(1) ;
T(1) = (Irradiance(1)*L(1)*(1-albedo_tot)/BoltzmannC).^(1/4); % Initial temperature of the planet



%% Loop over each time step using Euler method
for ii=1:N-1
    alphaG = 1 - alphaW(ii) - alphaB(ii); % percentage of ground uncovered by daisies
    albedo_tot = albedoG*alphaG + albedoW*alphaW(ii) + albedoB*alphaB(ii);

    % get local temperature at white daisy surface
    Tw = getLocalTemperature(Irradiance(ii),L(ii),T(ii),albedo_tot,albedoW);
    
    % get local temperature at black daisy surface
    Tb = getLocalTemperature(Irradiance(ii),L(ii),T(ii),albedo_tot,albedoB); 
    dTdt = getdTdt(Irradiance(ii),L(ii),albedo_tot,c,T(ii));

    betaTw =  getBeta(Tw) ; % get birth rate of white daisies
    betaTb =  getBeta(Tb) ; % get birth rate of black daisies

    MA =  [[alphaG*betaTw-gamma,0,0,0];...
        [0,alphaG*betaTb-gamma,0,0];...
        [0,0,0,BoltzmannC*T(ii).^4/c];...
        [0,0,0,-b*(alphaW(ii)+alphaB(ii))]];


    Y =  [alphaW(ii),alphaB(ii),T(ii),E(ii)]';
    F = [0, 0,dTdt,a]';

    Y = Y + dt.*(MA*Y + F) ; % Euler method tog et Y at step ii+1
    alphaW(ii+1) = Y(1) ; % get population of white daisies at step ii+1
    alphaB(ii+1) = Y(2) ; % get population of white daisies at step ii+1
    T(ii+1) = Y(3) ; % get global tempreature at step ii+1
    E(ii+1) = Y(4) ; % get greenhouse effect at step ii+1

end


    function [beta] =  getBeta(T)
        s = 70;
        Topt = 292.5;
        %     Topt is the optimal temperature in Kelvin at which the daisy can grow
        %     T is the local temperature
        beta = exp(-1/s*(T-Topt).^2); %  beta is the "birth" rate of daisies
    end

    function [dTdt] = getdTdt(S,L,A,c,T)
        % This function gets the time derivative of the global temperature
        dTdt = (S*L*(1-A)-BoltzmannC*T.^4)/c;
    end

    function [T_local, T] =  getLocalTemperature(I,L,T,albedo_tot,albedo_local)
        % This function calculates local temperature of the daisies or the ground + global temperature T
        q =  2.06e9;
        T_local = (q*(albedo_tot-albedo_local) + T.^4).^(1/4);
    end



end