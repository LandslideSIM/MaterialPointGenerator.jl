// 多边形绘制相关功能

class PolygonManager {
    constructor(canvas, gl, pointManager) {
        this.canvas = canvas;
        this.gl = gl;
        this.pointManager = pointManager; // 需要访问点数据
        
        // 多边形选择相关变量
        this.selectedPoints = []; // 存储已选择的点
        this.isSelectingPolygon = false; // 是否正在选择多边形
        this.highlightedPoint = null; // 当前高亮的点
        
        // WebGL相关变量
        this.polygonProgram = null; // 用于绘制多边形的WebGL程序
        this.polygonBuffer = null; // 用于存储多边形顶点的缓冲区
        this.polygonScaleLocation = null;
        this.polygonTranslationLocation = null;
        
        // UI元素
        this.instructionDisplay = this.createInstructionDisplay();
        
        // 初始化着色器
        this.initShaders();
        
        // 设置事件监听
        this.setupEventListeners();
    }
    
    // 创建提示信息元素
    createInstructionDisplay() {
        const display = document.createElement('div');
        display.className = 'instruction-display';
        display.style.position = 'absolute';
        display.style.bottom = '10px';
        display.style.left = '10px';
        display.style.background = 'rgba(0, 0, 0, 0.7)';
        display.style.color = 'white';
        display.style.padding = '5px 10px';
        display.style.borderRadius = '4px';
        display.style.fontSize = '12px';
        display.style.display = 'none';
        display.style.zIndex = '1000';
        this.canvas.parentElement.appendChild(display);
        return display;
    }
    
    // 初始化着色器
    initShaders() {
        // 线条的顶点着色器
        const lineVertexShaderSource = `
            attribute vec2 a_position;
            uniform vec2 u_scale;
            uniform vec2 u_translation;
            void main() {
                vec2 position = a_position * u_scale + u_translation;
                gl_Position = vec4(position, 0.0, 1.0);
            }
        `;
        
        // 线条的片段着色器 - 设置为明亮的黄色
        const lineFragmentShaderSource = `
            precision mediump float;
            void main() {
                gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0); // 纯黄色，更加明亮
            }
        `;
        
        // 创建线条着色器程序
        const lineVertexShader = this.createShader(this.gl.VERTEX_SHADER, lineVertexShaderSource);
        const lineFragmentShader = this.createShader(this.gl.FRAGMENT_SHADER, lineFragmentShaderSource);
        this.polygonProgram = this.createProgram(lineVertexShader, lineFragmentShader);
        
        // 创建缓冲区
        this.polygonBuffer = this.gl.createBuffer();
        
        // 获取着色器中的uniform位置
        this.polygonScaleLocation = this.gl.getUniformLocation(this.polygonProgram, 'u_scale');
        this.polygonTranslationLocation = this.gl.getUniformLocation(this.polygonProgram, 'u_translation');
        
        // 固定线宽和点大小常量
        this.POLYGON_LINE_WIDTH = 25.0; // 增加线宽，使线条更加明显
        this.POLYGON_POINT_SIZE = 15.0; // 固定的点大小
    }
    
    // 创建着色器
    createShader(type, source) {
        const shader = this.gl.createShader(type);
        this.gl.shaderSource(shader, source);
        this.gl.compileShader(shader);
        
        if (!this.gl.getShaderParameter(shader, this.gl.COMPILE_STATUS)) {
            console.error('Shader compilation error:', this.gl.getShaderInfoLog(shader));
            this.gl.deleteShader(shader);
            return null;
        }
        return shader;
    }
    
    // 创建程序
    createProgram(vertexShader, fragmentShader) {
        const program = this.gl.createProgram();
        this.gl.attachShader(program, vertexShader);
        this.gl.attachShader(program, fragmentShader);
        this.gl.linkProgram(program);

        if (!this.gl.getProgramParameter(program, this.gl.LINK_STATUS)) {
            console.error('Program link error:', this.gl.getProgramInfoLog(program));
            return null;
        }
        return program;
    }
    
    // 设置事件监听
    setupEventListeners() {
        // 鼠标移动处理
        this.canvas.addEventListener('mousemove', this.handleMouseMove.bind(this));
        
        // 鼠标点击处理
        this.canvas.addEventListener('click', this.handleClick.bind(this));
        
        // 键盘事件处理
        document.addEventListener('keydown', this.handleKeyDown.bind(this));
    }
    
    // 处理鼠标移动
    handleMouseMove(e) {
        if (!this.isSelectingPolygon || !this.pointManager.hasPoints()) return;
        
        // 查找最近的点
        const coords = this.pointManager.screenToDataCoordinates(e.clientX, e.clientY);
        const nearestPoint = this.pointManager.findNearestPoint(coords.x, coords.y);
        
        // 更新高亮点
        if (nearestPoint) {
            this.highlightedPoint = nearestPoint;
            this.pointManager.redraw();
        } else if (this.highlightedPoint) {
            this.highlightedPoint = null;
            this.pointManager.redraw();
        }
    }
    
    // 处理鼠标点击
    handleClick(e) {
        if (!this.isSelectingPolygon || !this.pointManager.hasPoints()) return;
        
        // 查找最近的点
        const coords = this.pointManager.screenToDataCoordinates(e.clientX, e.clientY);
        const nearestPoint = this.pointManager.findNearestPoint(coords.x, coords.y);
        
        if (nearestPoint) {
            // 检查是否与第一个点相同（用于闭合多边形）
            if (this.selectedPoints.length > 2 && 
                nearestPoint.x === this.selectedPoints[0].x && 
                nearestPoint.y === this.selectedPoints[0].y) {
                
                this.finishPolygonSelection();
                return;
            }
            
            // 检查点是否已被选择
            const alreadySelected = this.selectedPoints.some(p => 
                p.x === nearestPoint.x && p.y === nearestPoint.y);
                
            if (!alreadySelected) {
                this.selectedPoints.push(nearestPoint);
                this.pointManager.redraw();
            }
        }
    }
    
    // 处理键盘事件
    handleKeyDown(e) {
        if (!this.isSelectingPolygon) return;
        
        // Enter键闭合多边形
        if (e.key === 'Enter' || e.keyCode === 13) {
            if (this.selectedPoints.length >= 3) {
                this.finishPolygonSelection();
            } else {
                alert('At least 3 points are needed to form a polygon');
            }
        }
        
        // U键撤销上一个点
        if (e.key === 'u' || e.key === 'U' || e.keyCode === 85) {
            this.undoLastPoint();
        }
    }
    
    // 开始多边形选择
    startPolygonSelection() {
        if (!this.pointManager.hasPoints()) {
            alert('Please load point cloud data first');
            return;
        }
        
        this.isSelectingPolygon = true;
        this.selectedPoints = [];
        this.instructionDisplay.innerHTML = `
            Selecting polygon...<br>
            Mouse click: Select points<br>
            U key: Undo last point<br>
            Enter key: Close polygon
        `;
        this.instructionDisplay.style.display = 'block';
        this.canvas.style.cursor = 'crosshair';
    }
    
    // 完成多边形选择
    finishPolygonSelection() {
        if (this.selectedPoints.length < 3) {
            alert('At least 3 points are needed to form a polygon');
            return;
        }
        
        // 闭合多边形（确保第一个点与最后一个点相连）
        // 不需要添加额外点，因为我们已经处理闭合逻辑
        
        // 计算多边形面积
        let area = 0;
        for (let i = 0, j = this.selectedPoints.length - 1; i < this.selectedPoints.length; j = i++) {
            area += (this.selectedPoints[j].x + this.selectedPoints[i].x) * 
                   (this.selectedPoints[j].y - this.selectedPoints[i].y);
        }
        area = Math.abs(area / 2);
        
        // 先绘制闭合的多边形
        this.isSelectingPolygon = false;
        this.pointManager.redraw();
        
        // 创建面积显示元素
        this.showAreaInfo(area);
        
        // 输出结果
        console.log(`Polygon selection completed, ${this.selectedPoints.length} vertices, area: ${area.toFixed(2)} square units`);
        
        // 隐藏指令显示
        this.instructionDisplay.style.display = 'none';
        this.highlightedPoint = null;
    }
    
    // 显示面积信息
    showAreaInfo(area) {
        // 创建面积信息元素
        const areaDisplay = document.createElement('div');
        areaDisplay.className = 'area-display';
        areaDisplay.style.position = 'absolute';
        areaDisplay.style.top = '10px';
        areaDisplay.style.right = '10px';
        areaDisplay.style.background = 'rgba(0, 0, 0, 0.7)';
        areaDisplay.style.color = 'white';
        areaDisplay.style.padding = '10px 15px';
        areaDisplay.style.borderRadius = '4px';
        areaDisplay.style.fontSize = '14px';
        areaDisplay.style.zIndex = '1000';
        areaDisplay.innerHTML = `
            <strong>Polygon Information</strong><br>
            Vertices: ${this.selectedPoints.length}<br>
            Area: ${area.toFixed(2)} square units
        `;
        
        // 添加到canvas容器
        this.canvas.parentElement.appendChild(areaDisplay);
        
        // 5秒后自动移除
        setTimeout(() => {
            if (areaDisplay.parentElement) {
                areaDisplay.parentElement.removeChild(areaDisplay);
            }
        }, 5000);
    }
    
    // 撤销上一个选择的点
    undoLastPoint() {
        if (this.selectedPoints.length > 0) {
            this.selectedPoints.pop();
            this.pointManager.redraw();
        }
    }
    
    // 清除选择的多边形
    clearPolygon() {
        this.selectedPoints = [];
        this.isSelectingPolygon = false;
        this.highlightedPoint = null;
        this.instructionDisplay.style.display = 'none';
        this.canvas.style.cursor = 'default';
        this.pointManager.redraw();
    }
    
    // 绘制多边形
    draw(transform) {
        // 绘制已选择的多边形线条
        if (this.selectedPoints.length > 1) {
            const lineVertices = [];
            
            // 添加已选择点之间的连线
            for (let i = 0; i < this.selectedPoints.length; i++) {
                const point = this.selectedPoints[i];
                lineVertices.push(point.x, point.y);
            }
            
            // 如果已经完成多边形选择，添加闭合线段
            if (!this.isSelectingPolygon && this.selectedPoints.length > 2) {
                // 添加从最后一个点到第一个点的线段
                const firstPoint = this.selectedPoints[0];
                lineVertices.push(firstPoint.x, firstPoint.y);
            }
            // 如果正在选择中且当前高亮了一个点，添加一条临时连线
            else if (this.isSelectingPolygon && this.highlightedPoint && this.selectedPoints.length > 0) {
                const lastSelectedPoint = this.selectedPoints[this.selectedPoints.length - 1];
                lineVertices.push(lastSelectedPoint.x, lastSelectedPoint.y);
                lineVertices.push(this.highlightedPoint.x, this.highlightedPoint.y);
            }
            
            this.gl.useProgram(this.polygonProgram);
            this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.polygonBuffer);
            this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array(lineVertices), this.gl.STATIC_DRAW);
            
            const positionLocation = this.gl.getAttribLocation(this.polygonProgram, 'a_position');
            this.gl.enableVertexAttribArray(positionLocation);
            this.gl.vertexAttribPointer(positionLocation, 2, this.gl.FLOAT, false, 0, 0);
            
            this.gl.uniform2fv(this.polygonScaleLocation, transform.scale);
            this.gl.uniform2fv(this.polygonTranslationLocation, transform.translation);
            
            // 启用混合以使线条和背景混合
            this.gl.enable(this.gl.BLEND);
            this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA);
            
            // 设置线条宽度
            this.gl.lineWidth(this.POLYGON_LINE_WIDTH);
            
            // 如果不在选择中且已经有完整多边形，绘制闭合多边形
            if (!this.isSelectingPolygon && this.selectedPoints.length > 2) {
                this.gl.drawArrays(this.gl.LINE_LOOP, 0, this.selectedPoints.length);
            } 
            // 否则绘制线条
            else {
                // 绘制已确定的线段
                this.gl.drawArrays(this.gl.LINE_STRIP, 0, this.selectedPoints.length);
                
                // 如果有临时连线，单独绘制
                if (this.isSelectingPolygon && this.highlightedPoint) {
                    this.gl.drawArrays(this.gl.LINES, this.selectedPoints.length - 1, 2);
                }
            }
            
            // 禁用混合
            this.gl.disable(this.gl.BLEND);
        }
    }
    
    // 绘制选中点
    drawSelectedPoints(gl, program, pointSizeLocation, scaleLocation, translationLocation, transform) {
        if (this.selectedPoints.length === 0 && !this.highlightedPoint) return;
        
        // 先绘制所有已选择的点
        if (this.selectedPoints.length > 0) {
            const selectedVertices = [];
            this.selectedPoints.forEach(point => {
                selectedVertices.push(point.x, point.y);
            });
            
            if (selectedVertices.length > 0) {
                const positionBuffer = gl.createBuffer();
                gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
                gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(selectedVertices), gl.STATIC_DRAW);
                
                // 使用传入的程序
                gl.useProgram(program);
                
                const positionLocation = gl.getAttribLocation(program, 'a_position');
                gl.enableVertexAttribArray(positionLocation);
                gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);
                
                // 使用固定的点大小
                gl.uniform1f(pointSizeLocation, this.POLYGON_POINT_SIZE);
                gl.uniform2fv(scaleLocation, transform.scale);
                gl.uniform2fv(translationLocation, transform.translation);
                
                // 启用混合
                gl.enable(gl.BLEND);
                gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
                
                // 绘制选中点
                gl.drawArrays(gl.POINTS, 0, selectedVertices.length / 2);
                
                // 清理缓冲区
                gl.deleteBuffer(positionBuffer);
            }
        }
        
        // 再单独绘制当前高亮的点（如果有）- 使其更大更明显
        if (this.isSelectingPolygon && this.highlightedPoint) {
            const highlightedVertices = [this.highlightedPoint.x, this.highlightedPoint.y];
            
            const highlightBuffer = gl.createBuffer();
            gl.bindBuffer(gl.ARRAY_BUFFER, highlightBuffer);
            gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(highlightedVertices), gl.STATIC_DRAW);
            
            // 使用传入的程序
            gl.useProgram(program);
            
            const positionLocation = gl.getAttribLocation(program, 'a_position');
            gl.enableVertexAttribArray(positionLocation);
            gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);
            
            // 高亮点使用更大的尺寸
            gl.uniform1f(pointSizeLocation, this.POLYGON_POINT_SIZE * 1.5);
            gl.uniform2fv(scaleLocation, transform.scale);
            gl.uniform2fv(translationLocation, transform.translation);
            
            // 绘制高亮点
            gl.drawArrays(gl.POINTS, 0, 1);
            
            // 清理缓冲区
            gl.deleteBuffer(highlightBuffer);
        }
        
        // 禁用混合
        gl.disable(gl.BLEND);
    }
    
    // 检查是否有选择的多边形
    hasSelectedPolygon() {
        return this.selectedPoints.length > 0;
    }
    
    // 检查是否正在选择多边形
    isSelecting() {
        return this.isSelectingPolygon;
    }
    
    // 获取选中的点
    getSelectedPoints() {
        return this.selectedPoints;
    }
    
    // 从外部加载多边形
    loadPolygon(points) {
        if (points.length < 3) {
            console.error('Polygon requires at least 3 points');
            return false;
        }
        
        this.selectedPoints = points;
        this.isSelectingPolygon = false;
        
        // 计算多边形面积
        let area = 0;
        for (let i = 0, j = this.selectedPoints.length - 1; i < this.selectedPoints.length; j = i++) {
            area += (this.selectedPoints[j].x + this.selectedPoints[i].x) * 
                   (this.selectedPoints[j].y - this.selectedPoints[i].y);
        }
        area = Math.abs(area / 2);
        
        // 显示面积信息
        this.showAreaInfo(area);
        
        // 重绘以显示加载的多边形
        this.pointManager.redraw();
        
        return true;
    }
    
    // 重置WebGL状态
    resetWebGLState() {
        // 释放WebGL资源
        if (this.polygonProgram) {
            this.gl.deleteProgram(this.polygonProgram);
        }
        if (this.polygonBuffer) {
            this.gl.deleteBuffer(this.polygonBuffer);
        }
        
        // 重新初始化着色器
        this.initShaders();
        
        // 重置选择状态
        this.selectedPoints = [];
        this.isSelectingPolygon = false;
        this.highlightedPoint = null;
        
        // 隐藏提示
        this.instructionDisplay.style.display = 'none';
    }
} 