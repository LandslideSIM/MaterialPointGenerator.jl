// 点云数据管理类

class PointManager {
    constructor(canvas, gl) {
        this.canvas = canvas;
        this.gl = gl;
        this.points = []; // 存储渲染用的点数据
        this.originalPoints = []; // 存储原始的点数据，包括z坐标
        this.hillshadeValues = []; // 用于存储hillshade值
        this.bounds = { minX: 0, maxX: 0, minY: 0, maxY: 0, minZ: 0, maxZ: 0 };
        this.pointSize = 0.8; // 默认使用较小的点大小，提高百万级点云的清晰度
        
        // 获取设备像素比
        this.dpr = window.devicePixelRatio || 1;
        
        // Hillshade渲染器
        this.hillshadeRenderer = new HillshadeRenderer();
        
        // WebGL相关变量
        this.program = null;
        this.positionBuffer = null;
        this.hillshadeBuffer = null; // 为hillshade值添加缓冲区
        this.pointSizeLocation = null;
        this.scaleLocation = null;
        this.translationLocation = null;
        
        // 红色点着色器相关变量
        this.redPointProgram = null;
        this.redPointSizeLocation = null;
        this.redScaleLocation = null;
        this.redTranslationLocation = null;
        
        // 坐标显示元素
        this.coordsDisplay = this.createCoordsDisplay();
        
        // 初始化着色器
        this.initShaders();
        
        // 设置事件监听
        this.setupEventListeners();
        
        // 模块引用
        this.polygonManager = null;
        
        // UI更新回调
        this.uiUpdateCallback = null;
    }
    
    // 创建坐标显示元素
    createCoordsDisplay() {
        const display = document.createElement('div');
        display.className = 'coords-display';
        display.style.position = 'fixed';
        display.style.background = 'rgba(0, 0, 0, 0.7)';
        display.style.color = 'white';
        display.style.padding = '5px 10px';
        display.style.borderRadius = '4px';
        display.style.fontSize = '12px';
        display.style.pointerEvents = 'none';
        display.style.display = 'none';
        display.style.zIndex = '1000';
        document.body.appendChild(display);
        return display;
    }
    
    // 设置多边形管理器引用
    setPolygonManager(polygonManager) {
        this.polygonManager = polygonManager;
    }
    
    // 初始化着色器
    initShaders() {
        // 点的顶点着色器 - 支持高DPI和百万级点云
        const pointVertexShaderSource = `
            attribute vec3 a_position;
            attribute float a_hillshade; // 添加hillshade属性
            varying float v_hillshade;   // 传递给片段着色器
            uniform float u_pointSize;
            uniform vec2 u_scale;
            uniform vec2 u_translation;
            
            void main() {
                vec2 position = vec2(a_position.x, a_position.y) * u_scale + u_translation;
                gl_Position = vec4(position, 0.0, 1.0);
                gl_PointSize = u_pointSize;
                v_hillshade = a_hillshade; // 传递hillshade值
            }
        `;

        // 点的片段着色器 - 增强抗锯齿和平滑度
        const pointFragmentShaderSource = `
            precision highp float;  // 使用高精度以提高渲染质量
            varying float v_hillshade;
            
            void main() {
                // 使用hillshade值作为灰度值
                vec3 color = vec3(v_hillshade);
                
                // 绘制圆形点，增强边缘平滑
                float dist = length(gl_PointCoord - vec2(0.5));
                
                // 更平滑的边缘，减少锯齿
                float alpha = 1.0 - smoothstep(0.45, 0.5, dist);
                
                // 应用颜色和透明度
                gl_FragColor = vec4(color, alpha);
            }
        `;
        
        // 创建点的着色器程序
        const pointVertexShader = this.createShader(this.gl.VERTEX_SHADER, pointVertexShaderSource);
        const pointFragmentShader = this.createShader(this.gl.FRAGMENT_SHADER, pointFragmentShaderSource);
        this.program = this.createProgram(pointVertexShader, pointFragmentShader);
        
        // 创建缓冲区
        this.positionBuffer = this.gl.createBuffer();
        this.hillshadeBuffer = this.gl.createBuffer();
        
        // 获取着色器中的uniform位置
        this.pointSizeLocation = this.gl.getUniformLocation(this.program, 'u_pointSize');
        this.scaleLocation = this.gl.getUniformLocation(this.program, 'u_scale');
        this.translationLocation = this.gl.getUniformLocation(this.program, 'u_translation');
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
        // 鼠标移动显示坐标
        this.canvas.addEventListener('mousemove', this.handleMouseMove.bind(this));
        
        // 鼠标离开画布时隐藏坐标显示
        this.canvas.addEventListener('mouseleave', () => {
            this.coordsDisplay.style.display = 'none';
        });
        
        // 鼠标滚轮控制点大小
        this.canvas.addEventListener('wheel', this.handleWheel.bind(this));
    }
    
    // 处理鼠标移动
    handleMouseMove(e) {
        if (this.points.length === 0) return;
        
        // 转换为数据坐标
        const coords = this.screenToDataCoordinates(e.clientX, e.clientY);
        
        // 查找最近的点
        const nearestPoint = this.findNearestPoint(coords.x, coords.y);
        
        // 更新显示
        if (nearestPoint) {
            // 更新坐标显示内容，分三行显示
            this.coordsDisplay.innerHTML = `
                X: ${nearestPoint.x.toFixed(3)}<br>
                Y: ${nearestPoint.y.toFixed(3)}<br>
                Z: ${nearestPoint.z.toFixed(3)}
            `;
            
            // 定位到鼠标右下角
            this.coordsDisplay.style.left = `${e.clientX + 5}px`;
            this.coordsDisplay.style.top = `${e.clientY + 5}px`;
            this.coordsDisplay.style.display = 'block';
        } else {
            this.coordsDisplay.style.display = 'none';
        }
    }
    
    // 处理鼠标滚轮
    handleWheel(e) {
        e.preventDefault();
        const delta = e.deltaY > 0 ? -0.05 : 0.05; // 使用小步长以便精细调整
        
        // 根据点密度使用不同大小范围
        const pointCount = this.originalPoints.length;
        let minSize, maxSize;
        
        if (pointCount > 1000000) {
            // 百万级点云
            minSize = 0.1;
            maxSize = 2.0;
        } else if (pointCount > 100000) {
            // 10万-100万点
            minSize = 0.2;
            maxSize = 3.0;
        } else {
            // 少于10万点
            minSize = 0.3;
            maxSize = 5.0;
        }
        
        this.pointSize = Math.min(maxSize, Math.max(minSize, this.pointSize + delta));
        console.log(`Point size adjusted to: ${this.pointSize}`);
        this.redraw();
    }
    
    // 调整canvas尺寸并适应内容
    resizeCanvas() {
        const canvasContainer = this.canvas.parentElement;
        const containerWidth = canvasContainer.clientWidth - 40;
        const containerHeight = canvasContainer.clientHeight - 40;
        
        // 获取设备像素比以支持高DPI显示器
        const dpr = window.devicePixelRatio || 1;
        
        // 如果没有数据，使用默认尺寸
        if (!this.points.length) {
            // 设置物理像素 - 增加DPR支持
            this.canvas.width = containerWidth * dpr;
            this.canvas.height = containerHeight * dpr;
            this.canvas.style.width = `${containerWidth}px`;
            this.canvas.style.height = `${containerHeight}px`;
            this.gl.viewport(0, 0, this.canvas.width, this.canvas.height);
            return;
        }
        
        // 计算数据的宽高比
        const dataWidth = this.bounds.maxX - this.bounds.minX;
        const dataHeight = this.bounds.maxY - this.bounds.minY;
        const dataAspectRatio = dataWidth / dataHeight;
        
        // 创建一个固定尺寸的canvas
        // 使用正方形确保X和Y轴的单位长度一致
        const size = Math.min(containerWidth, containerHeight);
        
        // 根据数据比例设置canvas尺寸
        let canvasWidth, canvasHeight;
        if (dataAspectRatio > 1) {
            // Data is wider
            canvasWidth = size;
            canvasHeight = size / dataAspectRatio;
        } else {
            // Data is taller
            canvasWidth = size * dataAspectRatio;
            canvasHeight = size;
        }
        
        // 应用设备像素比，提高渲染精度
        this.canvas.width = canvasWidth * dpr;
        this.canvas.height = canvasHeight * dpr;
        
        // 使用相同的CSS尺寸
        this.canvas.style.width = `${canvasWidth}px`;
        this.canvas.style.height = `${canvasHeight}px`;
        
        // 居中显示canvas
        this.canvas.style.display = 'block';
        this.canvas.style.margin = '0 auto';
        
        // 更新WebGL视口
        this.gl.viewport(0, 0, this.canvas.width, this.canvas.height);
        
        console.log(`Canvas size: ${this.canvas.width}x${this.canvas.height} (DPR: ${dpr})`);
        
        // 重新绘制
        if (this.points.length > 0) {
            this.redraw();
        }
    }
    
    // 重新绘制
    redraw() {
        this.draw();
    }
    
    // 设置UI更新回调
    setUIUpdateCallback(callback) {
        this.uiUpdateCallback = callback;
    }
    
    // 获取点数
    getPointCount() {
        return this.originalPoints.length;
    }
    
    // 加载XYZ文件数据
    loadXYZData(text) {
        try {
            const lines = text.split('\n');
            
            // 重置数据
            this.points = [];
            this.originalPoints = [];
            this.hillshadeValues = [];
            let minX = Infinity, maxX = -Infinity;
            let minY = Infinity, maxY = -Infinity;
            let minZ = Infinity, maxZ = -Infinity;
            
            // 逐行处理数据，提取X、Y和Z坐标
            for (let i = 0; i < lines.length; i++) {
                const line = lines[i].trim();
                if (!line) continue;
                
                const parts = line.split(/\s+/);
                if (parts.length >= 3) {
                    const x = parseFloat(parts[0]);
                    const y = parseFloat(parts[1]);
                    const z = parseFloat(parts[2]);
                    
                    if (!isNaN(x) && !isNaN(y) && !isNaN(z)) {
                        this.points.push(x, y, z);
                        this.originalPoints.push({ x, y, z });
                        
                        // 更新边界
                        minX = Math.min(minX, x);
                        maxX = Math.max(maxX, x);
                        minY = Math.min(minY, y);
                        maxY = Math.max(maxY, y);
                        minZ = Math.min(minZ, z);
                        maxZ = Math.max(maxZ, z);
                    }
                }
            }
            
            // 检查是否有有效点数据
            if (this.points.length === 0) {
                console.error('No valid point data in the file');
                return false;
            }
            
            // 更新边界
            this.bounds = { minX, maxX, minY, maxY, minZ, maxZ };
            
            // 根据点云密度自动调整点大小
            this.autoAdjustPointSize();
            
            // 计算hillshade值
            this.calculateHillshadeValues();
            
            console.log(`Loaded ${this.originalPoints.length} points`);
            console.log(`X range: ${minX} to ${maxX}`);
            console.log(`Y range: ${minY} to ${maxY}`);
            console.log(`Z range: ${minZ} to ${maxZ}`);
            
            // 调整canvas大小以适应数据比例
            this.resizeCanvas();

            // 设置十字光标
            this.canvas.style.cursor = 'crosshair';
            
            // 调用UI更新回调
            if (this.uiUpdateCallback) {
                this.uiUpdateCallback(this.originalPoints.length);
            }
            
            return true;
        } catch (error) {
            console.error('Error loading XYZ data:', error);
            return false;
        }
    }
    
    // 自动调整点大小
    autoAdjustPointSize() {
        const pointCount = this.originalPoints.length;
        
        // 根据点数量动态调整点大小，默认高质量渲染
        if (pointCount > 2000000) {
            // 超过两百万点，使用最小的点
            this.pointSize = 0.3;
        } else if (pointCount > 1000000) {
            // 一百万到两百万点
            this.pointSize = 0.4;
        } else if (pointCount > 500000) {
            // 50万-100万点
            this.pointSize = 0.5;
        } else if (pointCount > 100000) {
            // 10万-50万点
            this.pointSize = 0.7;
        } else if (pointCount > 10000) {
            // 1万-10万点
            this.pointSize = 1.0;
        } else {
            // 少于1万点
            this.pointSize = 1.5;
        }
        
        console.log(`Auto-adjusted point size to ${this.pointSize} for ${pointCount} points (high quality rendering)`);
    }
    
    // 计算hillshade值
    calculateHillshadeValues() {
        console.log("Calculating hillshade values...");
        
        try {
            // 创建高程栅格
            const gridSize = Math.min(200, Math.max(50, Math.floor(Math.sqrt(this.originalPoints.length / 5))));
            this.hillshadeRenderer.createGridFromPoints(this.originalPoints, this.bounds, gridSize);
            
            // 计算hillshade值
            this.hillshadeValues = this.hillshadeRenderer.calculateHillshadeForPoints(this.originalPoints);
            
            if (this.hillshadeValues.length === 0) {
                console.warn("No hillshade values were generated!");
                this.hillshadeValues = new Array(this.originalPoints.length).fill(0.5);
            }
        } catch (error) {
            console.error("Error calculating hillshade values:", error);
            // 出错时使用默认值
            this.hillshadeValues = new Array(this.originalPoints.length).fill(0.5);
        }
    }
    
    // 清除所有点
    clearPoints() {
        this.points = [];
        this.originalPoints = [];
        this.bounds = { minX: 0, maxX: 0, minY: 0, maxY: 0, minZ: 0, maxZ: 0 };
        this.coordsDisplay.style.display = 'none';
        this.canvas.style.cursor = 'default';
        
        // 清空WebGL缓冲区
        if (this.positionBuffer) {
            this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.positionBuffer);
            this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array([]), this.gl.STATIC_DRAW);
        }
        
        // 重绘空场景
        this.gl.clearColor(0.21, 0.21, 0.21, 1.0);
        this.gl.clear(this.gl.COLOR_BUFFER_BIT);
        
        // 调用UI更新回调
        if (this.uiUpdateCallback) {
            this.uiUpdateCallback(0);
        }
        
        console.log('All point data cleared');
    }
    
    // 绘制点云
    draw() {
        try {
            const transform = this.calculateScaleAndTranslation();
            
            // 黑色背景
            this.gl.clearColor(0.21, 0.21, 0.21, 1.0);
            this.gl.clear(this.gl.COLOR_BUFFER_BIT);
            
            // 绘制点
            if (this.points.length > 0) {
                this.gl.useProgram(this.program);
                
                // 确保hillshade值可用
                if (!this.hillshadeValues || this.hillshadeValues.length !== this.originalPoints.length) {
                    console.warn("Hillshade values missing or mismatched, using defaults");
                    this.hillshadeValues = new Array(this.originalPoints.length).fill(0.5);
                }
                
                // 绑定位置缓冲区
                this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.positionBuffer);
                this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array(this.points), this.gl.STATIC_DRAW);
                const positionLocation = this.gl.getAttribLocation(this.program, 'a_position');
                if (positionLocation === -1) {
                    console.error("Could not get position attribute location");
                    return;
                }
                this.gl.enableVertexAttribArray(positionLocation);
                this.gl.vertexAttribPointer(positionLocation, 3, this.gl.FLOAT, false, 0, 0);
                
                // 绑定hillshade缓冲区
                this.gl.bindBuffer(this.gl.ARRAY_BUFFER, this.hillshadeBuffer);
                this.gl.bufferData(this.gl.ARRAY_BUFFER, new Float32Array(this.hillshadeValues), this.gl.STATIC_DRAW);
                const hillshadeLocation = this.gl.getAttribLocation(this.program, 'a_hillshade');
                if (hillshadeLocation === -1) {
                    console.error("Could not get hillshade attribute location");
                    return;
                }
                this.gl.enableVertexAttribArray(hillshadeLocation);
                this.gl.vertexAttribPointer(hillshadeLocation, 1, this.gl.FLOAT, false, 0, 0);
                
                // 根据点密度和设备像素比调整点大小
                const isHighDensity = this.originalPoints.length > 500000;
                let adjustedPointSize = this.pointSize * this.dpr;
                
                // 启用高质量渲染设置
                // 启用抗锯齿
                this.gl.enable(this.gl.SAMPLE_ALPHA_TO_COVERAGE);
                
                // 高密度点云时点大小略微调整
                if (isHighDensity) {
                    adjustedPointSize *= 0.85; // 高密度点云时略微减小点大小
                }
                
                // 启用额外的WebGL优化提示
                this.gl.hint(this.gl.GENERATE_MIPMAP_HINT, this.gl.NICEST);
                if (this.gl.FRAGMENT_SHADER_DERIVATIVE_HINT) {
                    this.gl.hint(this.gl.FRAGMENT_SHADER_DERIVATIVE_HINT, this.gl.NICEST);
                }
                
                console.log(`Rendering with adjusted point size: ${adjustedPointSize} (base: ${this.pointSize}, dpr: ${this.dpr})`);
                
                // 设置uniform变量
                this.gl.uniform1f(this.pointSizeLocation, adjustedPointSize);
                this.gl.uniform2fv(this.scaleLocation, transform.scale);
                this.gl.uniform2fv(this.translationLocation, transform.translation);
                
                // 启用混合以支持透明度
                this.gl.enable(this.gl.BLEND);
                this.gl.blendFunc(this.gl.SRC_ALPHA, this.gl.ONE_MINUS_SRC_ALPHA);
                
                // 绘制点
                const pointCount = this.points.length / 3;
                this.gl.drawArrays(this.gl.POINTS, 0, pointCount);
                
                // 禁用混合和抗锯齿
                this.gl.disable(this.gl.BLEND);
                this.gl.disable(this.gl.SAMPLE_ALPHA_TO_COVERAGE);
            } else {
                console.warn("No points to draw");
            }
            
            // 如果存在多边形管理器，绘制多边形和选中点
            if (this.polygonManager) {
                // 绘制多边形线条
                this.polygonManager.draw(transform);
                
                // 绘制选中点（确保在普通点之上）
                if (this.polygonManager.hasSelectedPolygon()) {
                    // 创建红色点的着色器，使用相同的顶点着色器代码
                    if (!this.redPointProgram) {
                        // 只在第一次需要时创建红色着色器程序
                        const pointVertexShaderSource = `
                            attribute vec2 a_position;
                            uniform float u_pointSize;
                            uniform vec2 u_scale;
                            uniform vec2 u_translation;
                            void main() {
                                vec2 position = a_position * u_scale + u_translation;
                                gl_Position = vec4(position, 0.0, 1.0);
                                gl_PointSize = u_pointSize;
                            }
                        `;
                        
                        const redPointFragmentShaderSource = `
                            precision highp float;
                            void main() {
                                // 计算到中心的距离
                                float dist = length(gl_PointCoord - vec2(0.5));
                                
                                // 创建明亮的红色点，有边缘光晕
                                vec3 color = vec3(1.0, 0.0, 0.0); // 鲜红色

                                // 创建明亮的内环和外环
                                float innerGlow = 1.0 - smoothstep(0.0, 0.4, dist);
                                float outerGlow = 1.0 - smoothstep(0.4, 0.5, dist);
                                
                                // 边缘更亮
                                if (dist > 0.35 && dist < 0.45) {
                                    color = vec3(1.0, 0.6, 0.6); // 偏亮的红色边缘
                                }
                                
                                // 应用透明度以保持点的圆形
                                float alpha = 1.0 - smoothstep(0.45, 0.5, dist);
                                
                                gl_FragColor = vec4(color, alpha);
                            }
                        `;
                        
                        const pointVertexShader = this.createShader(this.gl.VERTEX_SHADER, pointVertexShaderSource);
                        const redPointFragmentShader = this.createShader(this.gl.FRAGMENT_SHADER, redPointFragmentShaderSource);
                        this.redPointProgram = this.createProgram(pointVertexShader, redPointFragmentShader);
                        
                        // 获取着色器中的uniform位置
                        this.redPointSizeLocation = this.gl.getUniformLocation(this.redPointProgram, 'u_pointSize');
                        this.redScaleLocation = this.gl.getUniformLocation(this.redPointProgram, 'u_scale');
                        this.redTranslationLocation = this.gl.getUniformLocation(this.redPointProgram, 'u_translation');
                    }
                    
                    // 使用红色程序绘制选中点
                    this.polygonManager.drawSelectedPoints(
                        this.gl, 
                        this.redPointProgram, 
                        this.redPointSizeLocation, 
                        this.redScaleLocation, 
                        this.redTranslationLocation,
                        transform
                    );
                }
            }
            
            // 绘制测量工具（如果存在）
            const measureTool = window.measureTool;
            if (measureTool && measureTool.isMeasuring) {
                // 绘制测量线
                measureTool.draw(transform);
                
                // 确保红点着色器程序已初始化
                if (!this.redPointProgram) {
                    this.initRedPointShader();
                }
                
                // 绘制测量点
                if (this.redPointProgram) {
                    measureTool.drawSelectedPoints(
                        this.gl, 
                        this.redPointProgram, 
                        this.redPointSizeLocation, 
                        this.redScaleLocation, 
                        this.redTranslationLocation, 
                        transform
                    );
                    
                    // 创建一个临时的红点着色器，添加特殊的"外环"效果
                    const outerRingFragmentShaderSource = `
                        precision highp float;
                        void main() {
                            // 计算到中心的距离
                            float dist = length(gl_PointCoord - vec2(0.5));
                            
                            // 外环效果 - 只渲染外环部分
                            float alpha = 0.0;
                            
                            // 创建明亮的外环
                            if (dist > 0.4 && dist < 0.5) {
                                alpha = 1.0 - smoothstep(0.4, 0.5, dist);
                                alpha = alpha * 0.8; // 让外环半透明
                            }
                            
                            // 使用荧光黄色
                            vec3 color = vec3(1.0, 1.0, 0.0);
                            
                            gl_FragColor = vec4(color, alpha);
                        }
                    `;
                    
                    // 创建临时的外环程序
                    const outerRingFragmentShader = this.createShader(this.gl.FRAGMENT_SHADER, outerRingFragmentShaderSource);
                    const outerRingProgram = this.createProgram(
                        this.gl.getAttachedShaders(this.redPointProgram)[0], // 重用顶点着色器
                        outerRingFragmentShader
                    );
                    
                    // 获取uniform位置
                    const outerPointSizeLocation = this.gl.getUniformLocation(outerRingProgram, 'u_pointSize');
                    const outerScaleLocation = this.gl.getUniformLocation(outerRingProgram, 'u_scale');
                    const outerTranslationLocation = this.gl.getUniformLocation(outerRingProgram, 'u_translation');
                    
                    // 绘制外环
                    measureTool.drawSelectedPoints(
                        this.gl, 
                        outerRingProgram, 
                        outerPointSizeLocation, 
                        outerScaleLocation, 
                        outerTranslationLocation, 
                        transform
                    );
                    
                    // 清理临时资源
                    this.gl.deleteShader(outerRingFragmentShader);
                    this.gl.deleteProgram(outerRingProgram);
                }
            }
            
        } catch (error) {
            console.error("Error drawing points:", error);
        }
    }
    
    // 计算缩放和平移值
    calculateScaleAndTranslation() {
        if (!this.points.length || this.bounds.minX === this.bounds.maxX || this.bounds.minY === this.bounds.maxY) {
            return {
                scale: [0.01, 0.01],
                translation: [0, 0]
            };
        }
        
        // 数据范围
        const dataWidth = this.bounds.maxX - this.bounds.minX;
        const dataHeight = this.bounds.maxY - this.bounds.minY;
        
        // 计算缩放因子，保持等比例
        const scale = 1.8 / Math.max(dataWidth, dataHeight);
        
        // 数据中心点
        const dataCenterX = (this.bounds.minX + this.bounds.maxX) / 2;
        const dataCenterY = (this.bounds.minY + this.bounds.maxY) / 2;
        
        // 计算平移量（居中显示）
        const translationX = -dataCenterX * scale;
        const translationY = -dataCenterY * scale;
        
        return {
            scale: [scale, scale],
            translation: [translationX, translationY]
        };
    }
    
    // 将屏幕坐标转换为数据坐标
    screenToDataCoordinates(screenX, screenY) {
        const canvasRect = this.canvas.getBoundingClientRect();
        const transform = this.calculateScaleAndTranslation();
        
        // 转换为canvas相对坐标 (0 到 1)
        const canvasX = (screenX - canvasRect.left) / canvasRect.width;
        const canvasY = (screenY - canvasRect.top) / canvasRect.height;
        
        // 转换为WebGL坐标 (-1 到 1)
        const webglX = canvasX * 2 - 1;
        const webglY = -(canvasY * 2 - 1); // 翻转Y轴
        
        // 转换为数据坐标
        const dataX = (webglX - transform.translation[0]) / transform.scale[0];
        const dataY = (webglY - transform.translation[1]) / transform.scale[1];
        
        return { x: dataX, y: dataY };
    }
    
    // 在数据坐标中查找最近的点
    findNearestPoint(dataX, dataY) {
        if (this.originalPoints.length === 0) return null;
        
        let minDistance = Infinity;
        let nearestPoint = null;
        
        for (let i = 0; i < this.originalPoints.length; i++) {
            const point = this.originalPoints[i];
            const dx = point.x - dataX;
            const dy = point.y - dataY;
            const distance = Math.sqrt(dx * dx + dy * dy);
            
            if (distance < minDistance) {
                minDistance = distance;
                nearestPoint = point;
            }
        }
        
        // 计算数据单位的屏幕像素尺寸
        const dataWidth = this.bounds.maxX - this.bounds.minX;
        const canvasRect = this.canvas.getBoundingClientRect();
        const pixelsPerDataUnit = canvasRect.width / dataWidth;
        
        // 如果最近的点距离太远（超过点大小的2倍），返回null
        const threshold = (this.pointSize * 2) / pixelsPerDataUnit;
        return minDistance <= threshold ? nearestPoint : null;
    }
    
    // 检查是否有点
    hasPoints() {
        return this.points.length > 0;
    }
    
    // 获取点大小
    getPointSize() {
        return this.pointSize;
    }
    
    // 查找最接近给定坐标的点
    findClosestPoint(x, y) {
        if (this.originalPoints.length === 0) return null;
        
        let minDistance = Infinity;
        let closestPoint = null;
        
        for (let i = 0; i < this.originalPoints.length; i++) {
            const point = this.originalPoints[i];
            const dx = point.x - x;
            const dy = point.y - y;
            const distance = Math.sqrt(dx * dx + dy * dy);
            
            if (distance < minDistance) {
                minDistance = distance;
                closestPoint = point;
            }
        }
        
        return closestPoint;
    }
    
    // 获取多边形内的所有点
    getPointsInsidePolygon(polygon) {
        if (!polygon || polygon.length < 3) return [];
        
        const insidePoints = [];
        
        // 检查每个点是否在多边形内部
        for (let i = 0; i < this.originalPoints.length; i++) {
            const point = this.originalPoints[i];
            if (this.isPointInPolygon(point, polygon)) {
                insidePoints.push(point);
            }
        }
        
        return insidePoints;
    }
    
    // 判断点是否在多边形内部
    isPointInPolygon(point, polygon) {
        // 射线法（Ray Casting Algorithm）判断点是否在多边形内部
        const x = point.x;
        const y = point.y;
        let inside = false;
        
        for (let i = 0, j = polygon.length - 1; i < polygon.length; j = i++) {
            const xi = polygon[i].x;
            const yi = polygon[i].y;
            const xj = polygon[j].x;
            const yj = polygon[j].y;
            
            // 判断点是否在多边形的边上
            const onEdge = (y === yi && y === yj && ((x >= xi && x <= xj) || (x >= xj && x <= xi)));
            if (onEdge) return true;
            
            // 射线法判断点是否在内部
            const intersect = ((yi > y) !== (yj > y)) && (x < (xj - xi) * (y - yi) / (yj - yi) + xi);
            if (intersect) inside = !inside;
        }
        
        return inside;
    }
    
    // 重置WebGL状态
    resetWebGLState() {
        // 释放之前的WebGL资源
        if (this.program) {
            this.gl.deleteProgram(this.program);
        }
        if (this.redPointProgram) {
            this.gl.deleteProgram(this.redPointProgram);
        }
        if (this.positionBuffer) {
            this.gl.deleteBuffer(this.positionBuffer);
        }
        
        // 重新初始化着色器
        this.initShaders();
        
        // 重置红色点着色器程序
        this.redPointProgram = null;
        this.redPointSizeLocation = null;
        this.redScaleLocation = null;
        this.redTranslationLocation = null;
        
        // 默认设置
        this.pointSize = 0.8;
        this.bounds = { minX: 0, maxX: 0, minY: 0, maxY: 0 };
        
        // 调整canvas尺寸
        this.resizeCanvas();
    }
    
    // 添加初始化红点着色器的方法
    initRedPointShader() {
        // 创建红色点的着色器，使用相同的顶点着色器代码
        const pointVertexShaderSource = `
            attribute vec2 a_position;
            uniform float u_pointSize;
            uniform vec2 u_scale;
            uniform vec2 u_translation;
            void main() {
                vec2 position = a_position * u_scale + u_translation;
                gl_Position = vec4(position, 0.0, 1.0);
                gl_PointSize = u_pointSize;
            }
        `;
        
        const redPointFragmentShaderSource = `
            precision highp float;
            void main() {
                // 计算到中心的距离
                float dist = length(gl_PointCoord - vec2(0.5));
                
                // 创建明亮的红色点，有边缘光晕
                vec3 color = vec3(1.0, 0.0, 0.0); // 鲜红色

                // 创建明亮的内环和外环
                float innerGlow = 1.0 - smoothstep(0.0, 0.4, dist);
                float outerGlow = 1.0 - smoothstep(0.4, 0.5, dist);
                
                // 边缘更亮
                if (dist > 0.35 && dist < 0.45) {
                    color = vec3(1.0, 0.6, 0.6); // 偏亮的红色边缘
                }
                
                // 应用透明度以保持点的圆形
                float alpha = 1.0 - smoothstep(0.45, 0.5, dist);
                
                gl_FragColor = vec4(color, alpha);
            }
        `;
        
        const pointVertexShader = this.createShader(this.gl.VERTEX_SHADER, pointVertexShaderSource);
        const redPointFragmentShader = this.createShader(this.gl.FRAGMENT_SHADER, redPointFragmentShaderSource);
        this.redPointProgram = this.createProgram(pointVertexShader, redPointFragmentShader);
        
        // 获取着色器中的uniform位置
        this.redPointSizeLocation = this.gl.getUniformLocation(this.redPointProgram, 'u_pointSize');
        this.redScaleLocation = this.gl.getUniformLocation(this.redPointProgram, 'u_scale');
        this.redTranslationLocation = this.gl.getUniformLocation(this.redPointProgram, 'u_translation');
    }
} 