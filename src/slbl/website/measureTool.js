// 测量工具功能

class MeasureTool {
    constructor(canvas, gl, pointManager) {
        this.canvas = canvas;
        this.gl = gl;
        this.pointManager = pointManager;
        
        // 测量相关变量
        this.isMeasuring = false;
        this.selectedPoints = [];
        this.highlightedPoint = null;
        
        // WebGL相关变量
        this.measureLineProgram = null;
        this.measureLineBuffer = null;
        this.measureScaleLocation = null;
        this.measureTranslationLocation = null;
        
        // 添加闪烁效果的变量
        this.animationStartTime = Date.now();
        this.animationInterval = null;
        
        // 初始化着色器
        this.initShaders();
        
        // 事件监听器
        this.eventListeners = {
            mousemove: this.handleMouseMove.bind(this),
            click: this.handleClick.bind(this),
            keydown: this.handleKeyDown.bind(this)
        };
        
        // 指示信息元素
        this.instructionDisplay = this.createInstructionDisplay();
    }
    
    // 创建指示信息元素
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
        
        // 线条的片段着色器 - 使用鲜艳的亮黄色 (更加醒目)
        const lineFragmentShaderSource = `
            precision mediump float;
            void main() {
                gl_FragColor = vec4(1.0, 1.0, 0.0, 1.0); // 亮黄色，最醒目
            }
        `;
        
        // 创建线条着色器程序
        const lineVertexShader = this.createShader(this.gl.VERTEX_SHADER, lineVertexShaderSource);
        const lineFragmentShader = this.createShader(this.gl.FRAGMENT_SHADER, lineFragmentShaderSource);
        this.measureLineProgram = this.createProgram(lineVertexShader, lineFragmentShader);
        
        // 创建缓冲区
        this.measureLineBuffer = this.gl.createBuffer();
        
        // 获取着色器中的uniform位置
        this.measureScaleLocation = this.gl.getUniformLocation(this.measureLineProgram, 'u_scale');
        this.measureTranslationLocation = this.gl.getUniformLocation(this.measureLineProgram, 'u_translation');
        
        // 固定线宽和点大小常量 - 调整尺寸
        this.MEASURE_LINE_WIDTH = 40.0; // 进一步增大线宽
        this.MEASURE_POINT_SIZE = 20.0; // 点大小保持不变
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
        // 添加事件监听器
        this.canvas.addEventListener('mousemove', this.eventListeners.mousemove);
        this.canvas.addEventListener('click', this.eventListeners.click);
        document.addEventListener('keydown', this.eventListeners.keydown);
    }
    
    // 移除事件监听
    removeEventListeners() {
        // 移除事件监听器
        this.canvas.removeEventListener('mousemove', this.eventListeners.mousemove);
        this.canvas.removeEventListener('click', this.eventListeners.click);
        document.removeEventListener('keydown', this.eventListeners.keydown);
    }
    
    // 处理鼠标移动
    handleMouseMove(e) {
        if (!this.isMeasuring || !this.pointManager.hasPoints()) return;
        
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
        if (!this.isMeasuring || !this.pointManager.hasPoints()) return;
        
        // 查找最近的点
        const coords = this.pointManager.screenToDataCoordinates(e.clientX, e.clientY);
        const nearestPoint = this.pointManager.findNearestPoint(coords.x, coords.y);
        
        if (nearestPoint) {
            // 如果已经有两个点了，忽略当前点击
            if (this.selectedPoints.length >= 2) return;
            
            // 添加选中的点
            this.selectedPoints.push(nearestPoint);
            
            // 如果已经选择了两个点，计算距离并显示
            if (this.selectedPoints.length === 2) {
                this.calculateAndShowDistance();
            }
            
            this.pointManager.redraw();
        }
    }
    
    // 处理键盘事件
    handleKeyDown(e) {
        if (!this.isMeasuring) return;
        
        // Esc键取消测量
        if (e.key === 'Escape' || e.keyCode === 27) {
            this.stopMeasuring();
        }
        
        // Backspace或Delete键撤销上一个点
        if (e.key === 'Backspace' || e.keyCode === 8 || e.key === 'Delete' || e.keyCode === 46) {
            this.undoLastPoint();
        }
    }
    
    // 开始测量
    startMeasuring() {
        if (!this.pointManager.hasPoints()) {
            alert('Please load the point cloud data first.');
            return;
        }
        
        this.isMeasuring = true;
        this.selectedPoints = [];
        this.instructionDisplay.innerHTML = `
            Measurement mode...<br>
            Click: Select two points<br>
            Backspace/Delete: Undo the previous point<br>
            Esc: Cancel measurement
        `;
        this.instructionDisplay.style.display = 'block';
        this.canvas.style.cursor = 'crosshair';
        
        // 重置动画计时器
        this.animationStartTime = Date.now();
        
        // 启动动画循环以保持线条闪烁
        if (this.animationInterval) {
            clearInterval(this.animationInterval);
        }
        this.animationInterval = setInterval(() => {
            if (this.isMeasuring && (this.selectedPoints.length > 0 || this.highlightedPoint)) {
                this.pointManager.redraw();
            }
        }, 50); // 约20帧/秒的刷新率
        
        // 添加事件监听器
        this.setupEventListeners();
    }
    
    // 停止测量
    stopMeasuring() {
        // 停止动画
        if (this.animationInterval) {
            clearInterval(this.animationInterval);
            this.animationInterval = null;
        }
        
        this.isMeasuring = false;
        this.selectedPoints = [];
        this.highlightedPoint = null;
        this.instructionDisplay.style.display = 'none';
        this.canvas.style.cursor = 'default';
        
        // 移除事件监听器
        this.removeEventListeners();
        
        // 重绘
        this.pointManager.redraw();
    }
    
    // 撤销上一个选择的点
    undoLastPoint() {
        if (this.selectedPoints.length > 0) {
            this.selectedPoints.pop();
            this.pointManager.redraw();
        }
    }
    
    // 计算距离
    calculateDistance(point1, point2) {
        // 只考虑二维距离(x, y)
        const dx = point2.x - point1.x;
        const dy = point2.y - point1.y;
        return Math.sqrt(dx * dx + dy * dy);
    }
    
    // 计算距离并显示
    calculateAndShowDistance() {
        if (this.selectedPoints.length !== 2) return;
        
        const point1 = this.selectedPoints[0];
        const point2 = this.selectedPoints[1];
        const distance = this.calculateDistance(point1, point2);
        
        // 显示测量结果
        this.showDistanceResult(point1, point2, distance);
        
        // 继续测量，等待用户选择Esc退出或重新选择其他点
    }
    
    // 显示测量结果通知
    showDistanceResult(point1, point2, distance) {
        const message = `distance: ${distance.toFixed(3)}`;
        
        // 创建通知元素
        const notification = document.createElement('div');
        notification.className = 'notification info';
        notification.innerHTML = message;
        notification.style.right = '20px';
        notification.style.left = 'auto';
        notification.style.transform = 'translateY(-20px)';
        
        // 添加到body
        document.body.appendChild(notification);
        
        // 渐入效果
        setTimeout(() => {
            notification.style.opacity = '1';
            notification.style.transform = 'translateY(0)';
        }, 10);
        
        // 5秒后渐出
        setTimeout(() => {
            notification.style.opacity = '0';
            notification.style.transform = 'translateY(-20px)';
            
            // 移除元素
            setTimeout(() => {
                document.body.removeChild(notification);
            }, 300);
        }, 5000);
    }
    
    // 绘制测量线
    draw(transform) {
        // 如果不在测量状态或没有选中任何点，则返回
        if (!this.isMeasuring || this.selectedPoints.length === 0) return;
        
        // 判断是否应该绘制线条
        const shouldDrawLine = (this.selectedPoints.length === 2) || 
            (this.selectedPoints.length === 1 && this.highlightedPoint);
        
        if (shouldDrawLine) {
            const point1 = this.selectedPoints[0];
            const point2 = this.selectedPoints.length === 2 ? 
                this.selectedPoints[1] : this.highlightedPoint;
            
            const dx = point2.x - point1.x;
            const dy = point2.y - point1.y;
            const len = Math.sqrt(dx * dx + dy * dy);
            
            if (len > 0) {
                // 计算垂直向量用于偏移
                const perpX = -dy / len;
                const perpY = dx / len;
                
                // 使用更多并排的线，并增大偏移值使线看起来更粗
                
                // 绘制主线
                const mainLine = [
                    point1.x, point1.y,
                    point2.x, point2.y
                ];
                this.drawLinePrimitive(mainLine, transform);
                
                // 绘制偏移线 - 使用更大的偏移值和更多的线条
                // 使用20条偏移线，总共生成41条线（主线+20*2偏移线）
                for (let i = 1; i <= 20; i++) {
                    // 非线性递增，使线条更密集
                    const offset = 0.004 * Math.sqrt(i);
                    
                    // 绘制正偏移线
                    const vertices1 = [
                        point1.x + perpX * offset, point1.y + perpY * offset,
                        point2.x + perpX * offset, point2.y + perpY * offset
                    ];
                    
                    // 绘制负偏移线
                    const vertices2 = [
                        point1.x - perpX * offset, point1.y - perpY * offset,
                        point2.x - perpX * offset, point2.y - perpY * offset
                    ];
                    
                    // 绘制线条
                    this.drawLinePrimitive(vertices1, transform);
                    this.drawLinePrimitive(vertices2, transform);
                }
            }
        }
    }
    
    // 简化版线段绘制
    drawLinePrimitive(vertices, transform) {
        this.gl.useProgram(this.measureLineProgram);
        this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.measureLineBuffer);
        this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array(vertices), this.gl.STATIC_DRAW);
        
        const positionLocation = this.gl.getAttribLocation(this.measureLineProgram, 'a_position');
        this.gl.enableVertexAttribArray(positionLocation);
        this.gl.vertexAttribPointer(positionLocation, 2, this.gl.FLOAT, false, 0, 0);
        
        this.gl.uniform2fv(this.measureScaleLocation, transform.scale);
        this.gl.uniform2fv(this.measureTranslationLocation, transform.translation);
        
        // 设置线宽
        try {
            // 获取WebGL支持的最大线宽
            const maxLineWidth = this.gl.getParameter(this.gl.ALIASED_LINE_WIDTH_RANGE)[1];
            // 应用线宽，但不超过WebGL支持的最大值
            this.gl.lineWidth(Math.min(this.MEASURE_LINE_WIDTH, maxLineWidth));
        } catch(e) {
            // 如果出错，使用默认值
            this.gl.lineWidth(this.MEASURE_LINE_WIDTH);
        }
        
        // 绘制线条
        this.gl.drawArrays(this.gl.LINES, 0, vertices.length / 2);
    }
    
    // 绘制选中点
    drawSelectedPoints(gl, program, pointSizeLocation, scaleLocation, translationLocation, transform) {
        if (this.selectedPoints.length === 0 && !this.highlightedPoint) return;
        
        // 绘制白色边框 - 在实际点之前绘制更大的白色点作为边框
        if (this.selectedPoints.length > 0) {
            const selectedVertices = [];
            this.selectedPoints.forEach(point => {
                selectedVertices.push(point.x, point.y);
            });
            
            if (selectedVertices.length > 0) {
                // 创建临时白色边框着色器
                const borderFragmentShaderSource = `
                    precision highp float;
                    void main() {
                        float dist = length(gl_PointCoord - vec2(0.5));
                        float alpha = 1.0 - smoothstep(0.45, 0.5, dist);
                        gl_FragColor = vec4(1.0, 1.0, 1.0, alpha); // 白色边框
                    }
                `;
                
                const vertexShader = gl.getAttachedShaders(program)[0]; // 假设第一个是顶点着色器
                const borderFragmentShader = this.createShader(gl.FRAGMENT_SHADER, borderFragmentShaderSource);
                const borderProgram = this.createProgram(vertexShader, borderFragmentShader);
                
                // 获取uniform位置
                const borderPointSizeLocation = gl.getUniformLocation(borderProgram, 'u_pointSize');
                const borderScaleLocation = gl.getUniformLocation(borderProgram, 'u_scale');
                const borderTransLocation = gl.getUniformLocation(borderProgram, 'u_translation');
                
                // 绘制白色边框 - 使用比点稍大的尺寸
                const positionBuffer = gl.createBuffer();
                gl.bindBuffer(gl.ARRAY_BUFFER, positionBuffer);
                gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(selectedVertices), gl.STATIC_DRAW);
                
                gl.useProgram(borderProgram);
                
                const positionLocation = gl.getAttribLocation(borderProgram, 'a_position');
                gl.enableVertexAttribArray(positionLocation);
                gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);
                
                // 使用更大的点大小作为边框
                gl.uniform1f(borderPointSizeLocation, this.MEASURE_POINT_SIZE * 1.8);
                gl.uniform2fv(borderScaleLocation, transform.scale);
                gl.uniform2fv(borderTransLocation, transform.translation);
                
                gl.enable(gl.BLEND);
                gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
                
                gl.drawArrays(gl.POINTS, 0, selectedVertices.length / 2);
                
                // 清理资源
                gl.deleteBuffer(positionBuffer);
                gl.deleteShader(borderFragmentShader);
                gl.deleteProgram(borderProgram);
            }
        }
        
        // 现在正常绘制选中点
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
                
                // 使用固定的点大小 - 为选中的点使用更大的尺寸
                gl.uniform1f(pointSizeLocation, this.MEASURE_POINT_SIZE * 1.5);
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
        
        // 单独绘制当前高亮的点（如果有）
        if (this.isMeasuring && this.highlightedPoint) {
            // 首先绘制白色边框
            const highlightBorderFragmentShaderSource = `
                precision highp float;
                void main() {
                    float dist = length(gl_PointCoord - vec2(0.5));
                    float alpha = 1.0 - smoothstep(0.45, 0.5, dist);
                    gl_FragColor = vec4(1.0, 1.0, 1.0, alpha); // 白色边框
                }
            `;
            
            const vertexShader = gl.getAttachedShaders(program)[0]; // 假设第一个是顶点着色器
            const highlightBorderShader = this.createShader(gl.FRAGMENT_SHADER, highlightBorderFragmentShaderSource);
            const highlightBorderProgram = this.createProgram(vertexShader, highlightBorderShader);
            
            // 获取uniform位置
            const borderPointSizeLocation = gl.getUniformLocation(highlightBorderProgram, 'u_pointSize');
            const borderScaleLocation = gl.getUniformLocation(highlightBorderProgram, 'u_scale');
            const borderTransLocation = gl.getUniformLocation(highlightBorderProgram, 'u_translation');
            
            // 绘制白色边框
            const highlightedVertices = [this.highlightedPoint.x, this.highlightedPoint.y];
            
            const highlightBuffer = gl.createBuffer();
            gl.bindBuffer(gl.ARRAY_BUFFER, highlightBuffer);
            gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(highlightedVertices), gl.STATIC_DRAW);
            
            gl.useProgram(highlightBorderProgram);
            
            const positionLocation = gl.getAttribLocation(highlightBorderProgram, 'a_position');
            gl.enableVertexAttribArray(positionLocation);
            gl.vertexAttribPointer(positionLocation, 2, gl.FLOAT, false, 0, 0);
            
            // 使用更大的点大小作为边框
            gl.uniform1f(borderPointSizeLocation, this.MEASURE_POINT_SIZE * 2.3);
            gl.uniform2fv(borderScaleLocation, transform.scale);
            gl.uniform2fv(borderTransLocation, transform.translation);
            
            gl.enable(gl.BLEND);
            gl.blendFunc(gl.SRC_ALPHA, gl.ONE_MINUS_SRC_ALPHA);
            
            gl.drawArrays(gl.POINTS, 0, 1);
            
            // 清理
            gl.deleteShader(highlightBorderShader);
            gl.deleteProgram(highlightBorderProgram);
            
            // 然后绘制实际的高亮点
            const highlightBuffer2 = gl.createBuffer();
            gl.bindBuffer(gl.ARRAY_BUFFER, highlightBuffer2);
            gl.bufferData(gl.ARRAY_BUFFER, new Float32Array(highlightedVertices), gl.STATIC_DRAW);
            
            // 使用传入的程序
            gl.useProgram(program);
            
            const posLocation = gl.getAttribLocation(program, 'a_position');
            gl.enableVertexAttribArray(posLocation);
            gl.vertexAttribPointer(posLocation, 2, gl.FLOAT, false, 0, 0);
            
            // 高亮点使用更大的尺寸
            gl.uniform1f(pointSizeLocation, this.MEASURE_POINT_SIZE * 2.0);
            gl.uniform2fv(scaleLocation, transform.scale);
            gl.uniform2fv(translationLocation, transform.translation);
            
            // 绘制高亮点
            gl.drawArrays(gl.POINTS, 0, 1);
            
            // 清理缓冲区
            gl.deleteBuffer(highlightBuffer);
            gl.deleteBuffer(highlightBuffer2);
        }
        
        // 禁用混合
        gl.disable(gl.BLEND);
    }
    
    // 重置WebGL状态
    resetWebGLState() {
        // 停止动画
        if (this.animationInterval) {
            clearInterval(this.animationInterval);
            this.animationInterval = null;
        }
        
        // 释放WebGL资源
        if (this.measureLineProgram) {
            this.gl.deleteProgram(this.measureLineProgram);
        }
        if (this.measureLineBuffer) {
            this.gl.deleteBuffer(this.measureLineBuffer);
        }
        
        // 重新初始化着色器
        this.initShaders();
        
        // 重置状态
        this.selectedPoints = [];
        this.isMeasuring = false;
        this.highlightedPoint = null;
        
        // 隐藏提示
        this.instructionDisplay.style.display = 'none';
    }
} 