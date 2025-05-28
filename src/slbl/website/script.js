document.addEventListener('DOMContentLoaded', () => {
    // 获取DOM元素
    const canvas = document.getElementById('drawingCanvas');
    const gl = canvas.getContext('webgl');
    if (!gl) {
        alert('WebGL initialization failed. Your browser may not support it.');
        return;
    }
    
    // 获取UI元素
    const pointCountElement = document.getElementById('pointCount');
    const viewModeElement = document.getElementById('viewMode');
    
    // 初始化点管理器和多边形管理器
    const pointManager = new PointManager(canvas, gl);
    const polygonManager = new PolygonManager(canvas, gl, pointManager);
    const measureTool = new MeasureTool(canvas, gl, pointManager);
    
    // 使测量工具全局可访问，以便在PointManager中使用
    window.measureTool = measureTool;
    
    // 建立双向引用
    pointManager.setPolygonManager(polygonManager);
    
    // 设置UI更新回调
    pointManager.setUIUpdateCallback((pointCount) => {
        pointCountElement.textContent = `${pointCount.toLocaleString()} points`;
    });
    
    // 设置按钮事件监听
    setupButtonListeners(canvas, gl, pointManager, polygonManager, measureTool);
    
    // 监听窗口大小变化，保持比例
    window.addEventListener('resize', () => {
        pointManager.resizeCanvas();
    });
    
    // 初始化UI状态
    updateUIState(pointManager, polygonManager);
});

// 更新UI状态
function updateUIState(pointManager, polygonManager) {
    const pointCount = document.getElementById('pointCount');
    const viewMode = document.getElementById('viewMode');
    
    // 更新点数显示
    const count = pointManager.getPointCount();
    pointCount.textContent = count > 0 ? `${count.toLocaleString()} points` : '0 points';
    
    // 更新视图模式
    viewMode.textContent = count > 0 ? '2D View' : '2D View';
}

// 设置按钮事件监听
function setupButtonListeners(canvas, gl, pointManager, polygonManager, measureTool) {
    // 获取文件输入元素
    const xyzFileInput = document.getElementById('xyzFileInput');
    const xyFileInput = document.getElementById('xyFileInput');
    
    // 加载XYZ文件 - 直接使用文件输入事件
    xyzFileInput.addEventListener('change', (e) => {
        const file = e.target.files[0];
        if (file) {
            console.log(`Loading XYZ file: ${file.name}`);
            const reader = new FileReader();
            reader.onload = (event) => {
                const result = pointManager.loadXYZData(event.target.result);
                console.log(`XYZ file loading ${result ? 'successful' : 'failed'}`);
                
                // 更新UI状态
                updateUIState(pointManager, polygonManager);
                
                // 显示加载完成通知
                if (result) {
                    showNotification(`Loaded ${pointManager.getPointCount().toLocaleString()} points`);
                } else {
                    showNotification('Failed to load points', 'error');
                }
            };
            reader.readAsText(file);
        }
    });
    
    // 加载多边形XY文件 - 直接使用文件输入事件
    xyFileInput.addEventListener('change', (e) => {
        const file = e.target.files[0];
        if (file) {
            console.log(`Loading polygon file: ${file.name}`);
            const reader = new FileReader();
            reader.onload = (event) => {
                loadPolygonFromXY(event.target.result, pointManager, polygonManager);
            };
            reader.readAsText(file);
        }
    });
    
    // 清除多边形
    document.getElementById('clearPolygon').addEventListener('click', () => {
        // 停止测量模式
        if (measureTool.isMeasuring) {
            measureTool.stopMeasuring();
        }
        
        // 只清除多边形，保留点云数据
        polygonManager.clearPolygon();
        // 重新绘制以更新画面
        pointManager.redraw();
        showNotification('Polygon cleared');
    });
    
    // 清除所有数据
    document.getElementById('clearAll').addEventListener('click', () => {
        // 停止测量模式
        if (measureTool.isMeasuring) {
            measureTool.stopMeasuring();
        }
        
        // 清除点云和多边形
        pointManager.clearPoints();
        polygonManager.clearPolygon();
        
        // 重置文件输入框
        xyzFileInput.value = '';
        xyFileInput.value = '';
        
        // 重新初始化WebGL
        reinitializeWebGL(canvas, gl, pointManager, polygonManager, measureTool);
        
        // 更新UI状态
        updateUIState(pointManager, polygonManager);
        showNotification('All data cleared');
        
        console.log('All data cleared and WebGL state reset');
    });
    
    // 绘制多边形
    const plotPolygonButton = document.getElementById('plotPolygon');
    if (plotPolygonButton) {
        plotPolygonButton.addEventListener('click', () => {
            // 停止测量模式
            if (measureTool.isMeasuring) {
                measureTool.stopMeasuring();
            }
            
            polygonManager.startPolygonSelection();
        });
    }
    
    // 测量工具
    const measureButton = document.getElementById('measure');
    if (measureButton) {
        measureButton.addEventListener('click', () => {
            // 如果正在选择多边形，停止选择
            if (polygonManager.isSelecting()) {
                polygonManager.clearPolygon();
            }
            
            // 启动测量模式
            measureTool.startMeasuring();
        });
    }
    
    // 保存多边形
    document.getElementById('savePolygon').addEventListener('click', () => {
        // 如果有选择多边形，执行保存操作
        if (polygonManager.hasSelectedPolygon()) {
            savePolygonToXY(polygonManager.getSelectedPoints());
            showNotification('Polygon saved');
        } else {
            showNotification('Please select a polygon first', 'error');
        }
    });
    
    // 保存多边形内部的点
    document.getElementById('savePoints').addEventListener('click', () => {
        if (polygonManager.hasSelectedPolygon()) {
            const polygon = polygonManager.getSelectedPoints();
            const insidePoints = pointManager.getPointsInsidePolygon(polygon);
            
            if (insidePoints.length > 0) {
                savePointsToXYZ(insidePoints);
                showNotification(`Saved ${insidePoints.length} points`);
            } else {
                showNotification('No points inside the polygon', 'warning');
            }
        } else {
            showNotification('Please select a polygon first', 'error');
        }
    });
    
    // 添加着色选项相关的事件监听
    // 获取滑块和应用按钮元素
    const azimuthSlider = document.getElementById('azimuthSlider');
    const altitudeSlider = document.getElementById('altitudeSlider');
    const zFactorSlider = document.getElementById('zFactorSlider');
    const applyShading = document.getElementById('applyShading');
    
    // 显示滑块的当前值
    azimuthSlider.addEventListener('input', () => {
        document.getElementById('azimuthValue').textContent = `${azimuthSlider.value}°`;
    });
    
    altitudeSlider.addEventListener('input', () => {
        document.getElementById('altitudeValue').textContent = `${altitudeSlider.value}°`;
    });
    
    zFactorSlider.addEventListener('input', () => {
        document.getElementById('zFactorValue').textContent = zFactorSlider.value;
    });
    
    // 应用着色按钮
    applyShading.addEventListener('click', () => {
        if (!pointManager.hasPoints()) {
            showNotification('Please load point cloud data first', 'warning');
            return;
        }
        
        const azimuth = parseFloat(azimuthSlider.value);
        const altitude = parseFloat(altitudeSlider.value);
        const zFactor = parseFloat(zFactorSlider.value);
        
        // 更新hillshade参数
        pointManager.hillshadeRenderer.setLightingParameters(azimuth, altitude, zFactor);
        
        // 重新计算hillshade值
        pointManager.calculateHillshadeValues();
        
        // 重绘场景
        pointManager.redraw();
        
        showNotification('Shading updated');
    });
}

// 显示通知
function showNotification(message, type = 'info', duration = 3000) {
    // 创建通知元素
    const notification = document.createElement('div');
    notification.className = `notification ${type}`;
    notification.innerHTML = message;
    
    // 添加到body
    document.body.appendChild(notification);
    
    // 渐入效果
    setTimeout(() => {
        notification.style.opacity = '1';
        notification.style.transform = 'translateY(0)';
    }, 10);
    
    // 持续时间后渐出
    setTimeout(() => {
        notification.style.opacity = '0';
        notification.style.transform = 'translateY(-20px)';
        
        // 移除元素
        setTimeout(() => {
            document.body.removeChild(notification);
        }, 300);
    }, duration);
}

// 保存多边形为XY文件
function savePolygonToXY(points) {
    // 格式化点坐标数据为文本
    let content = '';
    
    // 对于每个点，添加其X和Y坐标到文本中
    points.forEach(point => {
        content += `${point.x} ${point.y}\n`;
    });
    
    // 添加第一个点作为闭合点
    if (points.length > 0) {
        const firstPoint = points[0];
        content += `${firstPoint.x} ${firstPoint.y}\n`;
    }
    
    // 创建Blob对象
    const blob = new Blob([content], { type: 'text/plain' });
    
    // 创建一个临时链接来下载文件
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    link.download = 'polygon.xy';
    
    // 触发点击事件来下载文件
    document.body.appendChild(link);
    link.click();
    
    // 清理
    document.body.removeChild(link);
    URL.revokeObjectURL(link.href);
}

// 保存点为XYZ文件
function savePointsToXYZ(points) {
    // 格式化点坐标数据为文本
    let content = '';
    
    // 添加每个点的XYZ坐标
    points.forEach(point => {
        content += `${point.x} ${point.y} ${point.z}\n`;
    });
    
    // 创建Blob对象
    const blob = new Blob([content], { type: 'text/plain' });
    
    // 创建一个临时链接来下载文件
    const link = document.createElement('a');
    link.href = URL.createObjectURL(blob);
    
    // 生成文件名，包含时间戳
    const timestamp = new Date().toISOString().replace(/[:.]/g, '-');
    link.download = `polygon_points_${timestamp}.xyz`;
    
    // 触发点击事件来下载文件
    document.body.appendChild(link);
    link.click();
    
    // 清理
    document.body.removeChild(link);
    URL.revokeObjectURL(link.href);
    
    // 显示保存信息
    alert(`Saved ${points.length} points to XYZ file`);
}

// 从XY文件加载多边形
function loadPolygonFromXY(content, pointManager, polygonManager) {
    // 检查是否有点云数据
    if (!pointManager.hasPoints()) {
        alert('Please load point cloud data first');
        return;
    }
    
    // 解析文件内容
    const lines = content.split('\n');
    const polygonPoints = [];
    
    // 从每行解析X和Y坐标
    for (let i = 0; i < lines.length; i++) {
        const line = lines[i].trim();
        if (!line) continue;
        
        const parts = line.split(/\s+/);
        if (parts.length >= 2) {
            const x = parseFloat(parts[0]);
            const y = parseFloat(parts[1]);
            
            if (!isNaN(x) && !isNaN(y)) {
                // 查找最近的点（因为我们需要关联到已有的点云）
                const nearestPoint = pointManager.findClosestPoint(x, y);
                if (nearestPoint) {
                    polygonPoints.push(nearestPoint);
                }
            }
        }
    }
    
    // 确保最后一个点不重复第一个点（我们会自动闭合）
    if (polygonPoints.length > 1 && 
        polygonPoints[0].x === polygonPoints[polygonPoints.length - 1].x && 
        polygonPoints[0].y === polygonPoints[polygonPoints.length - 1].y) {
        polygonPoints.pop();
    }
    
    if (polygonPoints.length >= 3) {
        // 清除当前多边形，然后加载新的
        polygonManager.clearPolygon();
        polygonManager.loadPolygon(polygonPoints);
    } else {
        alert('Failed to load polygon: insufficient points or invalid format');
    }
}

// 重新初始化WebGL
function reinitializeWebGL(canvas, gl, pointManager, polygonManager, measureTool) {
    // 清除WebGL状态
    gl.clear(gl.COLOR_BUFFER_BIT | gl.DEPTH_BUFFER_BIT);
    gl.clearColor(0.21, 0.21, 0.21, 1.0);
    gl.viewport(0, 0, canvas.width, canvas.height);
    
    // 重置canvas尺寸
    const canvasContainer = canvas.parentElement;
    const containerWidth = canvasContainer.clientWidth - 40;
    const containerHeight = canvasContainer.clientHeight - 40;
    canvas.width = containerWidth;
    canvas.height = containerHeight;
    canvas.style.width = `${containerWidth}px`;
    canvas.style.height = `${containerHeight}px`;
    
    // 更新视口
    gl.viewport(0, 0, canvas.width, canvas.height);
    
    // 重置管理器状态
    pointManager.resetWebGLState();
    polygonManager.resetWebGLState();
    if (measureTool) {
        measureTool.resetWebGLState();
    }
    
    // 绘制空白画布
    gl.clearColor(0.21, 0.21, 0.21, 1.0);
    gl.clear(gl.COLOR_BUFFER_BIT);
} 