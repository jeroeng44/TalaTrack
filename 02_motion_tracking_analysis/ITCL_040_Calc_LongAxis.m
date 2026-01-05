clear all;
clc;
close all;


%filename = 'P:\.stl';



fv = stlread(filename); % Load STL file

vertices = fv.Points; % Extract vertices from the loaded STL file

% Center the data
centeredVertices = vertices - mean(vertices, 1);

% Perform PCA
[coeff, ~, ~] = pca(centeredVertices);

% The first column of `coeff` corresponds to the long axis (principal eigenvector)
% Principal axes
longAxis = coeff(:, 1);       % First principal component (long axis)
intermediateAxis = coeff(:, 2); % Second principal component (intermediate axis)
shortAxis = coeff(:, 3);       % Third principal component (short axis)

disp('Long Axis')
disp(longAxis)


disp('intermediate Axis')
disp(intermediateAxis)


disp('Short Axis')
disp(shortAxis)



% Center the vertices
vertices = fv.Points;
centroid = mean(vertices, 1);
centeredVertices = vertices - centroid;

% Compute inertia tensor
I = zeros(3,3);
for i = 1:size(centeredVertices, 1)
    v = centeredVertices(i, :);
    I = I + (dot(v,v) * eye(3) - (v' * v));
end

% Get principal axes (eigenvectors of inertia tensor)
[eigVecs, eigVals] = eig(I);

% Eigenvectors are the principal axes
longAxis = eigVecs(:,1); % Corresponds to the smallest eigenvalue
intermediateAxis = eigVecs(:,2);
shortAxis = eigVecs(:,3);


disp('Long Axis')
disp(longAxis)


disp('intermediate Axis')
disp(intermediateAxis)


disp('Short Axis')
disp(shortAxis)