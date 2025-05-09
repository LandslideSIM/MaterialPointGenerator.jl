// hillshade.js - 简化版Horn算法的hillshade效果
// 基于点云数据的黑白hillshade渲染

class HillshadeRenderer {
    constructor() {
        // hillshade参数
        this.azimuth = 315; // 光源方位角（默认为西北方向）
        this.altitude = 35;  // 光源高度角
        this.zFactor = 2.0;  // Z值缩放因子
        this.resolution = 1.0; // 栅格分辨率
        
        // 栅格数据
        this.grid = null;
        this.gridSize = 100; // 默认栅格大小
        this.bounds = null;
    }
    
    // 设置光照参数
    setLightingParameters(azimuth, altitude, zFactor) {
        console.log(`Setting lighting parameters: azimuth=${azimuth}, altitude=${altitude}, zFactor=${zFactor}`);
        this.azimuth = azimuth;
        this.altitude = altitude;
        this.zFactor = zFactor;
    }
    
    // 从点云创建高程栅格
    createGridFromPoints(points, bounds, gridSize = 100) {
        console.log(`Creating elevation grid of size ${gridSize}x${gridSize}`);
        this.bounds = bounds;
        this.gridSize = gridSize;
        
        // 确定栅格分辨率
        const xResolution = (bounds.maxX - bounds.minX) / gridSize;
        const yResolution = (bounds.maxY - bounds.minY) / gridSize;
        this.resolution = Math.min(xResolution, yResolution);
        
        // 初始化栅格（值为null表示没有数据）
        this.grid = Array(gridSize).fill().map(() => Array(gridSize).fill(null));
        
        // 创建计数和总和数组来计算每个栅格单元的平均高度
        const counts = Array(gridSize).fill().map(() => Array(gridSize).fill(0));
        const sums = Array(gridSize).fill().map(() => Array(gridSize).fill(0));
        
        // 第一步：将点分配到栅格单元并计算每个单元的平均高度
        for (const point of points) {
            // 计算点在栅格中的位置
            const gridX = Math.floor((point.x - bounds.minX) / (bounds.maxX - bounds.minX) * (gridSize - 1));
            const gridY = Math.floor((point.y - bounds.minY) / (bounds.maxY - bounds.minY) * (gridSize - 1));
            
            // 确保在界限内
            if (gridX >= 0 && gridX < gridSize && gridY >= 0 && gridY < gridSize) {
                counts[gridY][gridX]++;
                sums[gridY][gridX] += point.z;
            }
        }
        
        // 计算平均高度
        for (let y = 0; y < gridSize; y++) {
            for (let x = 0; x < gridSize; x++) {
                if (counts[y][x] > 0) {
                    this.grid[y][x] = sums[y][x] / counts[y][x];
                }
            }
        }
        
        // 填充空值（使用简单邻近平均值）
        this.fillNullValues();
        
        console.log("Grid creation complete");
        return this.grid;
    }
    
    // 用简单邻近平均值填充空值
    fillNullValues() {
        // 找到最小有效高度作为默认值
        let minHeight = Infinity;
        for (let y = 0; y < this.gridSize; y++) {
            for (let x = 0; x < this.gridSize; x++) {
                if (this.grid[y][x] !== null && this.grid[y][x] < minHeight) {
                    minHeight = this.grid[y][x];
                }
            }
        }
        
        // 如果没有有效点，使用0作为默认值
        if (minHeight === Infinity) minHeight = 0;
        
        const tempGrid = JSON.parse(JSON.stringify(this.grid));
        
        // 迭代填充空值
        let hasNull = true;
        let iterations = 0;
        const maxIterations = 3; // 限制迭代次数
        
        while (hasNull && iterations < maxIterations) {
            hasNull = false;
            iterations++;
            
            for (let y = 0; y < this.gridSize; y++) {
                for (let x = 0; x < this.gridSize; x++) {
                    if (this.grid[y][x] === null) {
                        hasNull = true;
                        
                        // 收集周围非空值
                        const neighbors = [];
                        for (let dy = -1; dy <= 1; dy++) {
                            for (let dx = -1; dx <= 1; dx++) {
                                const ny = y + dy;
                                const nx = x + dx;
                                
                                if (ny >= 0 && ny < this.gridSize && nx >= 0 && nx < this.gridSize && 
                                    this.grid[ny][nx] !== null) {
                                    neighbors.push(this.grid[ny][nx]);
                                }
                            }
                        }
                        
                        // 用平均值填充
                        if (neighbors.length > 0) {
                            const sum = neighbors.reduce((a, b) => a + b, 0);
                            tempGrid[y][x] = sum / neighbors.length;
                        }
                    }
                }
            }
            
            // 更新grid
            this.grid = JSON.parse(JSON.stringify(tempGrid));
        }
        
        // 剩余空值用minHeight填充
        for (let y = 0; y < this.gridSize; y++) {
            for (let x = 0; x < this.gridSize; x++) {
                if (this.grid[y][x] === null) {
                    this.grid[y][x] = minHeight;
                }
            }
        }
    }
    
    // 计算单个栅格点的hillshade值（Horn算法简化版）
    calculateHillshade(x, y) {
        // 边界处理
        if (x <= 0 || x >= this.gridSize - 1 || y <= 0 || y >= this.gridSize - 1) {
            return 0.5; // 边缘返回中间灰色
        }
        
        // 获取周围8个点的高度
        const z1 = this.grid[y-1][x-1];
        const z2 = this.grid[y-1][x];
        const z3 = this.grid[y-1][x+1];
        const z4 = this.grid[y][x-1];
        const z6 = this.grid[y][x+1];
        const z7 = this.grid[y+1][x-1];
        const z8 = this.grid[y+1][x];
        const z9 = this.grid[y+1][x+1];
        
        // 计算x和y方向的梯度 (注意Z轴指向屏幕前方，所以梯度方向反转)
        const dzdx = ((z1 + 2*z4 + z7) - (z3 + 2*z6 + z9)) / (8 * this.resolution);
        const dzdy = ((z1 + 2*z2 + z3) - (z7 + 2*z8 + z9)) / (8 * this.resolution);
        
        // 应用z因子
        const dzdxz = dzdx * this.zFactor;
        const dzdyz = dzdy * this.zFactor;
        
        // 计算坡度
        const slope = Math.atan(Math.sqrt(dzdxz*dzdxz + dzdyz*dzdyz));
        
        // 计算坡向
        const aspect = Math.atan2(dzdy, -dzdx);
        
        // 转换光照角度为弧度
        const azimuthRad = (360.0 - this.azimuth + 90.0) * (Math.PI / 180.0);
        const altitudeRad = this.altitude * (Math.PI / 180.0);
        
        // 计算Hillshade
        let hillshade = Math.cos(slope) * Math.sin(altitudeRad) + 
                       Math.sin(slope) * Math.cos(altitudeRad) * 
                       Math.cos(azimuthRad - aspect);
        
        // 范围调整到0-1
        hillshade = (hillshade + 1) / 2;
        
        return hillshade;
    }
    
    // 为所有点计算hillshade值
    calculateHillshadeForPoints(points) {
        if (!this.grid) {
            console.error("Error: Grid not initialized");
            return Array(points.length).fill(0.5);
        }
        
        console.log(`Calculating hillshade values for ${points.length} points`);
        const hillshadeValues = [];
        
        for (const point of points) {
            // 计算点在栅格中的位置
            const gridX = Math.floor((point.x - this.bounds.minX) / (this.bounds.maxX - this.bounds.minX) * (this.gridSize - 1));
            const gridY = Math.floor((point.y - this.bounds.minY) / (this.bounds.maxY - this.bounds.minY) * (this.gridSize - 1));
            
            // 确保坐标有效
            if (gridX < 0 || gridX >= this.gridSize || gridY < 0 || gridY >= this.gridSize) {
                hillshadeValues.push(0.5); // 无效坐标使用默认值
                continue;
            }
            
            // 计算hillshade值
            const hillshade = this.calculateHillshade(gridX, gridY);
            hillshadeValues.push(hillshade);
        }
        
        console.log(`Generated ${hillshadeValues.length} hillshade values`);
        return hillshadeValues;
    }
} 