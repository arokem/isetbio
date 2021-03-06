function irradiance = oiCalculateIrradiance(scene,optics)
%Calculate optical image irradiance 
%
%  irradiance = oiCalculateIrradiance(scene,optics)
%
%  The scene spectral radiance (photons/s/m2/sr/nm) is turned into optical
%  image irradiance (photons/s/m2/nm) based on information in the optics.
%  The formula for converting radiance to irradiance is
%
%     irradiance = pi /(1 + 4*fN^2*(1+abs(m))^2)*radiance;
%
%  where m is the magnification and fN is the f-number of the lens.
%  Frequently, in online references one sees the simpler formula:
% 
%     irradiance = pi /(4*fN^2*(1+abs(m))^2)*radiance;
%
% (e.g., Gerald C. Holst, CCD Arrayas, Cameras and Displays, 2nd Edition,
% pp. 33-34 (1998))
%
%  This second formula is accurate for small angles, say when the sensor
%  sees only the paraxial rays.  The formula used here is more general and
%  includes the non-paraxial rays.
%
%  On the web one even finds simpler formulae, such as 
%
%     irradiance = pi/(4*FN^2) * radiance
%
% For example, this formula is used in these online notes
%
%   http://www.ece.arizona.edu/~dial/ece425/notes7.pdf
%   http://www.coe.montana.edu/ee/jshaw/teaching/RSS_S04/Radiometry_geometry_RSS.pdf
%
%  Reference:
%    The formula is derived in Peter Catrysse's dissertation (pp. 150-151).  
%    See also http://eeclass.stanford.edu/ee392b/, course handouts
%    William L. Wolfe, Introduction to Radiometry, SPIE Press, 1998.
%
% Copyright ImagEval Consultants, LLC, 2005.

% TODO:  What should the fnumber be when we are in SKIP mode for the model?

% Scene data are in radiance units
radiance = sceneGet(scene,'photons');

% oi = vcGetObject('oi');
switch(lower(opticsGet(optics,'model')))
    case 'raytrace'
        % I am not sure we identify the ray trace case properly.
        % If we are in the ray trace case, we get the object distance from the ray
        % trace structure.
        sDist = opticsGet(optics,'rtobjectdistance');
        fN    = opticsGet(optics,'rtEffectivefNumber');
        m     = opticsGet(optics,'rtmagnification');
    case {'skip'}
        m  = opticsGet(optics,'magnification');  % Always 1
        fN = opticsGet(optics,'fNumber');        % What should this be?
    case {'diffractionlimited','shiftinvariant'}
        sDist = sceneGet(scene,'distance');
        fN    = opticsGet(optics,'fNumber');     % What should this be?
        m     = opticsGet(optics,'magnification',sDist);
    otherwise
        error('Unknown optics model');
end

% Apply lens transmittance.
% Perhaps we should be getting the transmittance out of ZEMAX/CODEV
transmittance = opticsGet(optics,'transmittance');

% If transmittance is all 1s, we can skip this step.
if sum(transmittance) ~= length(transmittance)
    if length(transmittance) ~= sceneGet(scene,'nWave')
        error('Bad transmittance'); 
    end
    % Do this in a loop to avoid large memory demand
    for ii=1:length(transmittance)
        radiance(:,:,ii) = radiance(:,:,ii)*transmittance(ii);
    end
end

% Apply the formula that converts scene radiance to optical image
% irradiance
irradiance = pi /(1 + 4*fN^2*(1+abs(m))^2)*radiance;

return;
