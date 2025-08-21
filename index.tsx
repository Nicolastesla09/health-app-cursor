
import { jsx as _jsx, jsxs as _jsxs } from "react/jsx-runtime";
import React, { useState, useCallback, useRef, useMemo, useEffect } from 'react';
import { createRoot } from 'react-dom/client';
import { GoogleGenAI, Type } from "@google/genai";
import { UploadCloud, Bot, HeartPulse, BrainCircuit, TestTube2, User, Venus, Mars, RotateCcw, Send, ShieldCheck, CalendarDays, CheckCircle2, Activity, Scale, LogOut, History, Carrot, UtensilsCrossed, Info, Flame, Droplets, Bone, Filter, ArrowUpDown, FileDown, Briefcase, ChevronLeft, ChevronRight, Apple, Dumbbell, Sparkles, Moon, Sun } from 'lucide-react';
import { Radar, Line } from 'react-chartjs-2';
import { Chart as ChartJS, RadialLinearScale, PointElement, LineElement, Filler, Tooltip, Legend, CategoryScale, LinearScale } from 'chart.js';
import jsPDF from 'jspdf';
import html2canvas from 'html2canvas';

const radarBackgroundPlugin = {
  id: 'radarBackgroundPlugin',
  beforeDatasetsDraw: (chart) => {
    const { ctx, scales: { r } } = chart;
    if (!r || r.options.display === false) {
      return;
    }

    const ticksLength = r.getLabels().length;
    const isDark = document.documentElement.getAttribute('data-theme') === 'dark';

    const zones = [
      { max: 4, color: isDark ? 'rgba(239, 68, 68, 0.1)' : 'rgba(220, 53, 69, 0.15)' }, // Bad
      { max: 7, color: isDark ? 'rgba(234, 179, 8, 0.1)' : 'rgba(255, 193, 7, 0.15)' }, // Moderate
      { max: 10, color: isDark ? 'rgba(34, 197, 94, 0.1)' : 'rgba(40, 167, 69, 0.15)' }  // Good
    ];

    ctx.save();
    
    zones.reverse().forEach(zone => {
      ctx.fillStyle = zone.color;
      ctx.beginPath();
      const firstPoint = r.getPointPositionForValue(0, zone.max);
      ctx.moveTo(firstPoint.x, firstPoint.y);

      for (let i = 1; i < ticksLength; i++) {
        const point = r.getPointPositionForValue(i, zone.max);
        ctx.lineTo(point.x, point.y);
      }
      ctx.closePath();
      ctx.fill();
    });

    ctx.restore();
  }
};

ChartJS.register(RadialLinearScale, PointElement, LineElement, Filler, Tooltip, Legend, CategoryScale, LinearScale, radarBackgroundPlugin);

const ai = new GoogleGenAI({ apiKey: process.env.API_KEY });

const iconMap = { HeartPulse, BrainCircuit, ShieldCheck, Flame, Bone, Droplets, Activity, TestTube2 };

function wrapText(text, maxWidth) {
    if (!text) return [''];
    const words = text.split(' ');
    let lines = [];
    let currentLine = words[0] || '';

    for (let i = 1; i < words.length; i++) {
        let testLine = currentLine + ' ' + words[i];
        if (testLine.length > maxWidth) {
            lines.push(currentLine);
            currentLine = words[i];
        } else {
            currentLine = testLine;
        }
    }
    lines.push(currentLine);
    return lines;
}

const fileToGenerativePart = async (file: File) => {
  const base64EncodedDataPromise = new Promise<string>((resolve) => {
    const reader = new FileReader();
    reader.onloadend = () => resolve((reader.result as string).split(',')[1]);
    reader.readAsDataURL(file);
  });
  return {
    inlineData: { data: await base64EncodedDataPromise, mimeType: file.type },
  };
};

const getBmiInfo = (bmi) => {
    if (bmi < 18.5) return { classification: 'Thiếu cân', className: 'bmi-underweight' };
    if (bmi < 24.9) return { classification: 'Bình thường', className: 'bmi-normal' };
    if (bmi < 29.9) return { classification: 'Thừa cân', className: 'bmi-overweight' };
    return { classification: 'Béo phì', className: 'bmi-obese' };
};

const HealthRadarChart = ({ categories, theme }) => {
    const isDark = theme === 'dark';
    const gridColor = isDark ? 'rgba(255, 255, 255, 0.15)' : 'rgba(0, 0, 0, 0.1)';
    const pointLabelColor = isDark ? '#ccc' : '#444';
    const tickColor = isDark ? '#999' : '#666';
    const tickBackdropColor = isDark ? 'rgba(30,30,30,0.75)' : 'rgba(255, 255, 255, 0.75)';

    const chartData = {
        labels: categories.map(c => c.categoryName),
        datasets: [
            {
                label: 'Điểm',
                data: categories.map(c => c.score),
                backgroundColor: 'rgba(90, 138, 58, 0.2)',
                borderColor: 'rgba(90, 138, 58, 1)',
                pointBackgroundColor: 'rgba(90, 138, 58, 1)',
                pointBorderColor: '#fff',
                pointHoverBackgroundColor: '#fff',
                pointHoverBorderColor: 'rgba(90, 138, 58, 1)',
                borderWidth: 2,
                pointRadius: 4,
                pointHoverRadius: 6
            },
        ],
    };

    const chartOptions = {
        scales: { 
            r: { 
                angleLines: { color: gridColor }, 
                grid: { color: gridColor },
                suggestedMin: 0, 
                suggestedMax: 10, 
                pointLabels: { 
                    font: { size: 12, weight: '500' }, 
                    color: pointLabelColor,
                    padding: 3,
                    callback: function(label) {
                        if (!Array.isArray(label)) {
                           return String(label).split(' ');
                        }
                        const wordsPerLine = 2;
                        const lines = [];
                        for (let i = 0; i < label.length; i += wordsPerLine) {
                            lines.push(label.slice(i, i + wordsPerLine).join(' '));
                        }
                        return lines;
                    }
                }, 
                ticks: { 
                    display: true,
                    stepSize: 2,
                    backdropColor: tickBackdropColor,
                    backdropPadding: 2,
                    color: tickColor,
                    font: {
                        size: 10
                    }
                },
            } 
        },
        plugins: {
            legend: { display: false },
            tooltip: {
                callbacks: {
                    title: (tooltipItems) => {
                       const label = tooltipItems[0].label;
                       if (Array.isArray(label)) {
                           return label.join(' ');
                       }
                       return label || '';
                    },
                    label: (context) => {
                        const category = categories[context.dataIndex];
                        const score = context.parsed.r.toFixed(1);
                        const question = 'Vì sao có điểm này?';
                        const summary = category.summary;
                        const wrappedSummary = wrapText(summary, 35);
                        
                        return [
                            `Điểm: ${score} / 10`,
                            '',
                            question,
                            ...wrappedSummary
                        ];
                    }
                },
                 bodyFont: { size: 12 },
                 titleFont: { weight: 'bold', size: 14 },
                 bodySpacing: 4,
                 padding: 12,
                 boxPadding: 4,
                 multiKeyBackground: 'transparent',
                 backgroundColor: isDark ? 'rgba(0,0,0,0.9)' : 'rgba(0,0,0,0.85)',
                 titleColor: '#fff',
                 bodyColor: '#fff'
            }
        },
        maintainAspectRatio: false,
    };

    return _jsx(Radar, { data: chartData, options: chartOptions });
};

const HistoryChart = ({ history, onPointClick, theme }) => {
    const isDark = theme === 'dark';
    const gridColor = isDark ? 'rgba(255, 255, 255, 0.1)' : 'rgba(0, 0, 0, 0.1)';
    const tickColor = isDark ? '#bbb' : '#666';
    const borderColor = isDark ? '#98c379' : '#5a8a3a';

    const chartData = {
        labels: history.map(item => {
            const date = new Date(item.date);
            const day = String(date.getDate()).padStart(2, '0');
            const month = String(date.getMonth() + 1).padStart(2, '0');
            const year = date.getFullYear();
            return `${day}/${month}/${year}`;
        }),
        datasets: [{
            label: 'Điểm Sức khỏe Tổng thể',
            data: history.map(item => item.analysis.overallHealthScore.score),
            fill: false,
            borderColor: borderColor,
            pointBackgroundColor: '#fff',
            pointBorderColor: borderColor,
            pointHoverBackgroundColor: borderColor,
            pointHoverBorderColor: '#fff',
            pointRadius: 5,
            pointHoverRadius: 7,
            borderWidth: 2.5,
            tension: 0.3
        }]
    };
    const chartOptions = {
        scales: { 
            y: { 
                beginAtZero: true, 
                max: 100,
                grid: {
                    drawBorder: false,
                    color: gridColor,
                    borderDash: [5, 5],
                },
                 ticks: {
                    padding: 10,
                    color: tickColor
                }
            },
            x: {
                grid: {
                    display: false,
                },
                 ticks: {
                    padding: 10,
                    color: tickColor
                }
            }
        },
        plugins: {
            legend: {
                display: false
            }
        },
        layout: {
            padding: {
                right: 20,
                left: 10
            }
        },
        onClick: (evt, elements) => {
            if (elements.length > 0) {
                const index = elements[0].index;
                onPointClick(history[index]);
            }
        },
        maintainAspectRatio: false,
    };
    return _jsx(Line, { data: chartData, options: chartOptions });
};

const AppHeader = ({ appView, setAppView, setSelectedHistoryItem, resetPlans, handleSignOut }) => _jsxs("header", { className: "header", children: [_jsxs("div", { className: "header-main", children: [_jsx(BrainCircuit, { className: "icon" }), _jsx("h1", { children: "Trợ lý Phân tích Xét nghiệm AI" })] }), _jsx("p", { children: "Tải lên kết quả xét nghiệm để nhận phân tích toàn diện và theo dõi sức khỏe theo thời gian." }), _jsxs("nav", { className: "app-nav", children: [_jsx("button", { onClick: () => { setAppView('form'); setSelectedHistoryItem(null); resetPlans(); }, className: appView === 'form' ? 'active' : '', children: "Phân tích mới" }), _jsx("button", { onClick: () => { setAppView('history'); setSelectedHistoryItem(null); resetPlans(); }, className: appView === 'history' ? 'active' : '', children: "Lịch sử Sức khỏe" }), _jsx("button", { onClick: () => { setAppView('menuPlanner'); }, className: appView === 'menuPlanner' ? 'active' : '', children: "Thực đơn AI" }), _jsx("button", { onClick: () => { setAppView('workoutPlanner'); }, className: appView === 'workoutPlanner' ? 'active' : '', children: "Lịch tập AI" }), _jsxs("div", { className: "nav-separator" }), _jsx("button", { onClick: handleSignOut, className: "sign-out-button", "aria-label": "Sign out", children: _jsx(LogOut, { size: 20 }) })] })] });

const AnalysisResultView = ({ resultData, isHistory, theme, setSelectedHistoryItem, handleSaveResult, resetForm }) => {
    const [showOnlyAbnormal, setShowOnlyAbnormal] = useState(false);
    const [sortAbnormalFirst, setSortAbnormalFirst] = useState(true);
    const [isExportingPdf, setIsExportingPdf] = useState(false);
    const reportRef = useRef(null);

    const { overallHealthScore, bmiAnalysis, healthAnalysis, metrics, recommendedFoods } = resultData.analysis;
    const inputData = resultData.inputs;
    
    const heightInMeters = parseFloat(inputData.height) / 100;
    const bmi = parseFloat(inputData.weight) / (heightInMeters * heightInMeters);
    const bmiInfo = getBmiInfo(bmi);

    const handleExportPdf = async () => {
        if (!reportRef.current) {
            console.error("Report element not found");
            return;
        }
        setIsExportingPdf(true);
    
        const reportElement = reportRef.current;
        const actions = reportElement.querySelector('.results-actions');
        if (actions) {
            actions.style.display = 'none'; // Hide buttons during export
        }
    
        const pdf = new jsPDF({
            orientation: 'p',
            unit: 'mm',
            format: 'a4',
        });
        const pdfWidth = pdf.internal.pageSize.getWidth();
        const pdfHeight = pdf.internal.pageSize.getHeight();
        const margin = 15; // Increased margin for better look
        const contentWidth = pdfWidth - margin * 2;
        const contentHeight = pdfHeight - margin * 2;
    
        const sections = reportElement.querySelectorAll('.pdf-section');
    
        try {
            for (let i = 0; i < sections.length; i++) {
                const section = sections[i];
                
                const canvas = await html2canvas(section, {
                    scale: 2, // Higher scale for better quality
                    useCORS: true,
                    logging: false,
                    backgroundColor: document.documentElement.getAttribute('data-theme') === 'dark' ? '#1e1e1e' : '#ffffff',
                });
    
                const imgData = canvas.toDataURL('image/png');
                const imgProps = pdf.getImageProperties(imgData);
                
                let finalImgHeight = (imgProps.height * contentWidth) / imgProps.width;
                let finalImgWidth = contentWidth;
    
                if (finalImgHeight > contentHeight) {
                    finalImgWidth = (imgProps.width * contentHeight) / imgProps.height;
                    finalImgHeight = contentHeight;
                }
                
                if (i > 0) {
                    pdf.addPage();
                }
                
                const x = (pdfWidth - finalImgWidth) / 2;
                const y = margin;
                
                pdf.addImage(imgData, 'PNG', x, y, finalImgWidth, finalImgHeight);
            }
    
            const today = new Date().toISOString().slice(0, 10);
            pdf.save(`Health-Analysis-Report-${today}.pdf`);
    
        } catch (error) {
            console.error("Error exporting to PDF: ", error);
            alert("Đã xảy ra lỗi khi xuất file PDF. Vui lòng thử lại.");
        } finally {
            if (actions) {
                actions.style.display = 'flex'; // Restore buttons
            }
            setIsExportingPdf(false);
        }
    };

    const getStoreInfo = (storeName) => {
        switch (storeName) {
            case 'Lotte Mart': return { url: (food) => `https://www.lottemart.vn/search?keyword=${encodeURIComponent(food)}`, logo: 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/23/Lotte_Mart_logo.svg/1280px-Lotte_Mart_logo.svg.png', name: 'Lotte Mart' };
            case 'Co.op Food': return { url: (food) => `https://cooponline.vn/search/?text=${encodeURIComponent(food)}`, logo: 'https://cooponline.vn/wp-content/uploads/2021/05/logo-coop-online.png', name: 'Co.op Online' };
            case 'Bách Hóa Xanh': return { url: (food) => `https://www.bachhoaxanh.com/tim-kiem?key=${encodeURIComponent(food)}`, logo: 'https://cdn.haitrieu.com/wp-content/uploads/2022/03/Logo-Bach-Hoa-Xanh-V.png', name: 'Bách Hóa Xanh' };
            default: return null;
        }
    };

    const getCategoryClass = (score) => {
        if (score > 7) return 'good';
        if (score > 4) return 'moderate';
        return 'bad';
    };

    const displayedMetrics = useMemo(() => {
        const abnormalClassifications = ['High', 'Cao', 'Low', 'Thấp'];
        let filtered = metrics;
        if (showOnlyAbnormal) {
            filtered = filtered.filter(m => abnormalClassifications.includes(m.classification));
        }
        if (sortAbnormalFirst) {
            return [...filtered].sort((a, b) => {
                const isAAbnormal = abnormalClassifications.includes(a.classification);
                const isBAbnormal = abnormalClassifications.includes(b.classification);
                if (isAAbnormal && !isBAbnormal) return -1;
                if (!isAAbnormal && isBAbnormal) return 1;
                return 0;
            });
        }
        return filtered;
    }, [metrics, showOnlyAbnormal, sortAbnormalFirst]);

    return _jsxs("div", { className: "results-container", ref: reportRef, children: [_jsxs("div", { className: "pdf-section", children: [_jsxs("h2", { children: [_jsx(TestTube2, { className: "icon" }), "Kết quả Phân tích", isHistory && _jsxs("span", { className: "history-date-chip", children: ["Ngày: ", new Date(resultData.date).toLocaleDateString('vi-VN')] })] }), _jsxs("div", { className: "results-header-grid", children: [_jsxs("div", { className: "health-score-card", children: [_jsx("h3", { children: "Điểm Sức khỏe" }), _jsxs("div", { className: "health-score-value-wrapper", children: [_jsxs("p", { className: "health-score-value", children: [overallHealthScore.score.toFixed(0), _jsx("span", { children: "/100" })] }), _jsx("span", { className: "health-score-label", children: overallHealthScore.label })] }), _jsxs("div", { className: "health-score-tooltip", children: [_jsx(Info, { size: 16 }), _jsxs("div", { className: "tooltip-content", children: [_jsx("h4", { children: "Cách tính điểm" }), _jsx("p", { children: overallHealthScore.explanation })] })] })] }), _jsxs("div", { className: "body-analysis-card", children: [_jsx("h3", { children: "Phân tích Cơ thể" }), _jsxs("div", { className: "body-analysis-grid", children: [_jsxs("div", { children: ["Tuổi: ", _jsx("strong", { children: inputData.age })] }), _jsxs("div", { children: ["Giới tính: ", _jsx("strong", { children: inputData.gender })] }), _jsxs("div", { children: ["Cao: ", _jsx("strong", { children: `${inputData.height} cm` })] }), _jsxs("div", { children: ["Nặng: ", _jsx("strong", { children: `${inputData.weight} kg` })] }), _jsxs("div", { className: "bmi-item", children: ["BMI: ", _jsxs("strong", { className: `bmi-value ${bmiInfo.className}`, children: [bmi.toFixed(1), " ", _jsx("span", { children: bmiInfo.classification })] })] })] }), _jsx("p", { className: "bmi-summary", children: bmiAnalysis.summary })] })] })] }), _jsxs("div", { className: "health-overview-section pdf-section", children: [_jsxs("h2", { children: [_jsx(Activity, { className: "icon" }), "Tổng quan Sức khỏe Chi tiết"] }), _jsxs("div", { className: "overview-content", children: [_jsx("div", { className: "chart-container", children: _jsx(HealthRadarChart, { categories: healthAnalysis.categories, theme: theme }) }), _jsx("div", { className: "category-summary-grid", children: healthAnalysis.categories.map(cat => {
                    const IconComponent = iconMap[cat.iconName] || Activity;
                    return _jsxs("div", { className: `category-card status-bg-${getCategoryClass(cat.score)}`, children: [_jsxs("div", { className: "category-card-header", children: [_jsx(IconComponent, { className: "category-icon", size: 22 }), _jsx("h4", { children: Array.isArray(cat.categoryName) ? cat.categoryName.join(' ') : cat.categoryName }), _jsx("div", { className: `score-circle status-border-${getCategoryClass(cat.score)}`, children: _jsx("span", { children: cat.score.toFixed(1) }) })] }), _jsx("p", { className: "summary", children: cat.summary })] }, cat.categoryName.join(''));
                }) })] })] }), _jsxs("div", { className: "pdf-section", children: [_jsxs("h2", { children: [_jsx(HeartPulse, { className: "icon" }), "Chỉ số Xét nghiệm Chi tiết"] }), _jsxs("div", { className: "table-controls", children: [_jsxs("div", { className: "control-group", children: [_jsxs("label", { htmlFor: "sort-toggle", children: [_jsx(ArrowUpDown, { size: 14 }), " Bất thường lên đầu"] }), _jsx("label", { className: "switch", children: [_jsx("input", { id: "sort-toggle", type: "checkbox", checked: sortAbnormalFirst, onChange: () => setSortAbnormalFirst(v => !v) }), _jsx("span", { className: "slider round" })] })] }), _jsxs("div", { className: "control-group", children: [_jsxs("label", { htmlFor: "filter-toggle", children: [_jsx(Filter, { size: 14 }), " Chỉ hiện bất thường"] }), _jsx("label", { className: "switch", children: [_jsx("input", { id: "filter-toggle", type: "checkbox", checked: showOnlyAbnormal, onChange: () => setShowOnlyAbnormal(v => !v) }), _jsx("span", { className: "slider round" })] })] })] }), _jsx("div", { className: "table-wrapper", children: _jsxs("table", { className: "results-table", children: [_jsx("thead", { children: _jsxs("tr", { children: [_jsx("th", { children: "Chỉ số" }), _jsx("th", { children: "Kết quả" }), _jsx("th", { children: "Ngưỡng tham chiếu" }), _jsx("th", { children: "Trạng thái" })] }) }), _jsx("tbody", { children: displayedMetrics.map((metric, index) => _jsxs("tr", { className: `status-row-${metric.classification.replace(/\s+/g, '-')}`, children: [_jsx("td", { "data-label": "Chỉ số", children: metric.name }), _jsxs("td", { "data-label": "Kết quả", children: [metric.value, " ", metric.unit] }), _jsx("td", { "data-label": "Ngưỡng tham chiếu", children: metric.referenceRange }), _jsx("td", { "data-label": "Trạng thái", children: _jsx("span", { className: `status-badge status-${metric.classification.replace(/\s+/g, '-')}`, children: metric.classification }) })] }, index)) })] }) })] }), _jsxs("div", { className: "recommendation-section pdf-section", children: [_jsxs("h2", { children: [_jsx(Carrot, { className: "icon", color: "#fd7e14" }), "Gợi ý Thực phẩm"] }), _jsx("div", { className: "card-grid", children: recommendedFoods.map((food, i) => {
                    const storeInfo = getStoreInfo(food.suggestedStore);
                    return _jsxs("div", { className: "product-card", children: [_jsx("h4", { children: food.foodName }), _jsx("p", { className: "benefit", children: food.benefit }), _jsx("p", { className: "dosage", children: [_jsx(UtensilsCrossed, { size: 16 }), food.servingSuggestion] }), storeInfo && _jsxs("a", { href: storeInfo.url(food.foodName), target: "_blank", rel: "noopener noreferrer", className: "store-button", children: [_jsx("img", { src: storeInfo.logo, alt: `${storeInfo.name} logo` }), `Tìm tại ${storeInfo.name}`] })] }, i);
                }) })] }), isHistory ? _jsx("button", { onClick: () => setSelectedHistoryItem(null), className: "action-button", style: { marginTop: '2rem', width: '100%' }, children: "Quay lại Lịch sử" }) : _jsxs("div", { className: "results-actions", children: [_jsx("button", { onClick: handleSaveResult, className: "action-button save-button", children: "Lưu Kết quả" }), _jsx("button", { onClick: handleExportPdf, disabled: isExportingPdf, className: "action-button export-button", children: isExportingPdf ? "Đang xuất..." : _jsxs(React.Fragment, { children: [_jsx(FileDown, { size: 18 }), "Xuất PDF"] }) }), _jsx("button", { onClick: resetForm, className: "action-button", children: _jsxs("div", { style: { display: 'flex', alignItems: 'center', gap: '8px' }, children: [_jsx(RotateCcw, {}), "Phân tích lại"] }) })] })] });
};

const PlanTableWithControls = ({ children }) => {
    const scrollContainerRef = useRef(null);
    const [canScroll, setCanScroll] = useState({ left: false, right: false, show: false });

    const checkScrollability = useCallback(() => {
        const el = scrollContainerRef.current;
        if (!el) return;

        const hasHorizontalScroll = el.scrollWidth > el.clientWidth;
        const scrollLeft = el.scrollLeft;
        const scrollWidth = el.scrollWidth;
        const clientWidth = el.clientWidth;
        
        setCanScroll({
            show: hasHorizontalScroll,
            left: scrollLeft > 5,
            right: scrollLeft < scrollWidth - clientWidth - 5,
        });
    }, []);

    useEffect(() => {
        const scrollEl = scrollContainerRef.current;
        if (!scrollEl) return;

        checkScrollability();

        const observer = new ResizeObserver(checkScrollability);
        observer.observe(scrollEl);
        scrollEl.addEventListener('scroll', checkScrollability, { passive: true });
        
        window.addEventListener('load', checkScrollability);

        return () => {
            observer.unobserve(scrollEl);
            scrollEl.removeEventListener('scroll', checkScrollability);
            window.removeEventListener('load', checkScrollability);
        };
    }, [checkScrollability]);

    const handleScroll = (direction) => {
        const el = scrollContainerRef.current;
        if (el) {
            const scrollAmount = el.clientWidth * 0.8;
            el.scrollBy({
                left: direction === 'right' ? scrollAmount : -scrollAmount,
                behavior: 'smooth',
            });
        }
    };
    
    return _jsxs("div", { className: `plan-table-with-controls-wrapper ${canScroll.show ? 'has-scroll' : ''}`, children: [
        _jsx("button", { 
            className: "scroll-button scroll-button-left",
            onClick: () => handleScroll('left'), 
            disabled: !canScroll.left,
            "aria-label": "Cuộn trái",
            children: _jsx(ChevronLeft, { size: 24 })
        }),
        _jsx("div", { className: "plan-table-container", ref: scrollContainerRef, children: children }),
        _jsx("button", { 
            className: "scroll-button scroll-button-right",
            onClick: () => handleScroll('right'), 
            disabled: !canScroll.right,
            "aria-label": "Cuộn phải",
            children: _jsx(ChevronRight, { size: 24 })
        })
    ]});
};


const MealPlanDisplay = ({ plan }) => {
    const meals = ['breakfast', 'lunch', 'dinner'];
    const mealLabels = { breakfast: 'Bữa Sáng', lunch: 'Bữa Trưa', dinner: 'Bữa Tối' };

    return _jsxs("div", { className: "plan-display-outer-container", children: [
        _jsx("h3", { className: "plan-table-title", children: "Kế hoạch Ăn uống" }),
        _jsx(PlanTableWithControls, { children: _jsxs("table", { className: "plan-table", children: [
            _jsx("thead", { children: _jsxs("tr", { children: [
                _jsx("th", {}), 
                plan.map((p) => _jsx("th", { children: p.day }, p.day))
            ] }) }), 
            _jsxs("tbody", { children: [
                meals.map(meal => _jsxs("tr", { children: [
                    _jsx("td", { className: "meal-label", children: mealLabels[meal] }), 
                    plan.map(dayPlan => _jsxs("td", { children: [
                        _jsx("p", { className: "dish-name", children: dayPlan[meal]?.dishName || 'N/A' }), 
                        _jsx("p", { className: "dish-notes", children: dayPlan[meal]?.notes || '' })
                    ] }, `${dayPlan.day}-${meal}`))
                ] }, meal)), 
                _jsxs("tr", { children: [
                    _jsx("td", { className: "meal-label", children: "Mẹo Hàng Ngày" }), 
                    plan.map(dayPlan => _jsx("td", { children: _jsxs("div", { className: "daily-tip-cell", children: [
                        _jsx(Flame, { size: 16 }), 
                        _jsx("span", { children: dayPlan.dailyTip })
                    ] }) }, `${dayPlan.day}-tip`))
                ] })
            ]})
        ]})})
    ]});
};

const WorkoutPlanDisplay = ({ plan }) => {
    const weeklyPlan = plan;

    return _jsxs("div", { className: "plan-display-outer-container", children: [
        _jsx("h3", { className: "plan-table-title", children: "Kế hoạch Tập luyện" }),
        _jsx(PlanTableWithControls, { children: _jsxs("table", { className: "plan-table", children: [
            _jsx("thead", { children: _jsxs("tr", { children: [
                _jsx("th", {}), 
                weeklyPlan.map((p) => _jsxs("th", { children: [
                    p.day, 
                    _jsx("span", { className: `workout-focus-chip ${p.workoutFocus === 'Ngày nghỉ' ? 'rest-day-chip' : ''}`, children: p.workoutFocus })
                ] }, p.day))
            ] }) }), 
            _jsxs("tbody", { children: [
                _jsxs("tr", { children: [
                    _jsx("td", { className: "meal-label", children: "Bài tập" }), 
                    weeklyPlan.map(dayPlan => _jsx("td", { children: (dayPlan.workoutFocus !== 'Ngày nghỉ' && dayPlan.exercises?.length > 0) ? 
                        (_jsx("ul", { className: "exercise-list", children: dayPlan.exercises.map((ex, i) => _jsxs("li", { children: [
                            _jsx("strong", { children: ex.name }), ": ", ex.sets, " x ", ex.reps, _jsx("br", {}), _jsx("span", { children: ex.notes })
                        ] }, i)) })) : 
                        (_jsx("p", { className: "rest-day-text", children: "Nghỉ ngơi và phục hồi." })) 
                    }, dayPlan.day))
                ] }), 
                _jsxs("tr", { children: [
                    _jsx("td", { className: "meal-label", children: "Mẹo Thể chất" }), 
                    weeklyPlan.map(dayPlan => _jsx("td", { children: _jsxs("div", { className: "daily-tip-cell", children: [
                        _jsx(Flame, { size: 16 }), 
                        _jsx("span", { children: dayPlan.dailyFitnessTip })
                    ] }) }, `${dayPlan.day}-tip`))
                ] })
            ]})
        ]})})
    ]});
};

const PlanGeneratorView = ({ planType, planRequest, onPlanRequestChange, handleGeneratePlan, isGeneratingPlan, error, generatedMealPlan, generatedWorkoutPlan, analysisResult, userHistory }) => {
    const title = planType === 'menu' ? 'Tạo Thực đơn AI' : 'Tạo Lịch tập AI';
    const icon = planType === 'menu' ? _jsx(Apple, { className: "icon" }) : _jsx(Dumbbell, { className: "icon" });
    const generatedPlan = planType === 'menu' ? generatedMealPlan : generatedWorkoutPlan;
    const hasHealthData = analysisResult || userHistory.length > 0;

    if (!hasHealthData) {
        return _jsx("div", { className: "placeholder-container", children: "Vui lòng thực hiện một phân tích sức khỏe trước để AI có thể tạo kế hoạch cá nhân hóa cho bạn." });
    }

    return _jsxs("div", { className: "planner-container", children: [_jsxs("h2", { children: [icon, title] }), _jsxs("div", { className: "planner-controls", children: [_jsxs("div", { className: "plan-request-input-group", children: [_jsx("label", { htmlFor: "plan-request", children: "Yêu cầu kế hoạch của bạn:" }), _jsx("input", { type: "text", id: "plan-request", className: "plan-request-input", value: planRequest, onChange: (e) => onPlanRequestChange(e.target.value), placeholder: "VD: Thực đơn 7 ngày, tập 3 buổi/tuần T2,4,6" })] }), _jsxs("button", { onClick: () => handleGeneratePlan(planType), disabled: isGeneratingPlan || !planRequest, className: "generate-button", children: [isGeneratingPlan ? "Đang tạo..." : "Tạo kế hoạch", _jsx(Sparkles, { size: 18 })] })] }), error && _jsx("div", { className: "error-container small", children: _jsx("p", { children: error }) }), isGeneratingPlan && _jsxs("div", { className: "loading-container", children: [_jsx("div", { className: "spinner" }), _jsx("p", { children: planType === 'menu' ? 'AI đang nấu thực đơn cho bạn...' : 'AI đang xây dựng lịch tập...' })] }), !isGeneratingPlan && !generatedPlan && _jsx("div", { className: "placeholder-container", children: "Nhập yêu cầu của bạn và nhấn 'Tạo kế hoạch' để bắt đầu." }), generatedPlan && (planType === 'menu' ? _jsx(MealPlanDisplay, { plan: generatedMealPlan }) : _jsx(WorkoutPlanDisplay, { plan: generatedWorkoutPlan }))] });
};


const App = () => {
    const [currentUser, setCurrentUser] = useState(null);
    const [view, setView] = useState('auth'); // auth, app
    const [appView, setAppView] = useState('form'); // form, results, history, menuPlanner, workoutPlanner

    // Form state
    const [age, setAge] = useState('');
    const [height, setHeight] = useState('');
    const [weight, setWeight] = useState('');
    const [gender, setGender] = useState(null);
    const [occupation, setOccupation] = useState('');
    const [files, setFiles] = useState([]);
    const [analysisResult, setAnalysisResult] = useState(null);
    const [isLoading, setIsLoading] = useState(false);
    const [loadingMessage, setLoadingMessage] = useState('');
    const [error, setError] = useState(null);
    const fileInputRef = useRef(null);

    // History state
    const [userHistory, setUserHistory] = useState([]);
    const [selectedHistoryItem, setSelectedHistoryItem] = useState(null);

    // Planner state
    const [generatedMealPlan, setGeneratedMealPlan] = useState(null);
    const [generatedWorkoutPlan, setGeneratedWorkoutPlan] = useState(null);
    const [isGeneratingPlan, setIsGeneratingPlan] = useState(false);
    const [planRequest, setPlanRequest] = useState('');
    
    // Auth state
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [isLogin, setIsLogin] = useState(true);
    const [authError, setAuthError] = useState('');
    
    // Theme state
    const [theme, setTheme] = useState(() => localStorage.getItem('theme') || 'light');

    useEffect(() => {
        document.documentElement.setAttribute('data-theme', theme);
        localStorage.setItem('theme', theme);
    }, [theme]);
    
    const toggleTheme = () => {
        setTheme(prevTheme => (prevTheme === 'light' ? 'dark' : 'light'));
    };

    useEffect(() => {
        const loggedInUser = JSON.parse(localStorage.getItem('currentUser'));
        if (loggedInUser) {
            setCurrentUser(loggedInUser);
            setView('app');
            loadHistory(loggedInUser.email);
        }
    }, []);

    const loadHistory = (userEmail) => {
        const history = JSON.parse(localStorage.getItem(`health_history_${userEmail}`)) || [];
        setUserHistory(history.sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()));
    };

    const handleAuth = () => {
        setAuthError('');
        const users = JSON.parse(localStorage.getItem('users')) || [];
        if (isLogin) {
            const user = users.find(u => u.email === email && u.password === password);
            if (user) {
                localStorage.setItem('currentUser', JSON.stringify(user));
                setCurrentUser(user);
                setView('app');
                loadHistory(user.email);
            } else {
                setAuthError('Email hoặc mật khẩu không đúng.');
            }
        } else {
            if (users.some(u => u.email === email)) {
                setAuthError('Email này đã được sử dụng.');
                return;
            }
            const newUser = { email, password };
            users.push(newUser);
            localStorage.setItem('users', JSON.stringify(users));
            localStorage.setItem('currentUser', JSON.stringify(newUser));
            setCurrentUser(newUser);
            setView('app');
        }
    };

    const handleSignOut = () => {
        localStorage.removeItem('currentUser');
        setCurrentUser(null);
        setView('auth');
        // Reset all state
        resetForm();
        setUserHistory([]);
    };

    const isFormValid = useMemo(() => age && gender && files.length > 0 && height && weight && occupation, [age, gender, files, height, weight, occupation]);

    const handleFileChange = (e) => {
        if (e.target.files) {
            setFiles(Array.from(e.target.files));
        }
    };

    const handleAreaClick = () => fileInputRef.current?.click();

    const resetForm = () => {
        setAge(''); setHeight(''); setWeight(''); setGender(null); setOccupation(''); setFiles([]); setAnalysisResult(null); setIsLoading(false); setError(null);
        setAppView('form');
    };
    
    const resetPlans = () => {
        setGeneratedMealPlan(null);
        setGeneratedWorkoutPlan(null);
        setPlanRequest('');
    };

    const handleAnalysis = async () => {
        if (!isFormValid) {
            setError("Vui lòng nhập đầy đủ tất cả các thông tin và tải lên ít nhất một tệp.");
            return;
        }

        setIsLoading(true);
        setError(null);
        const loadingMessages = ["Đang chuẩn bị phân tích...", "Đang trích xuất dữ liệu từ các tệp...", "AI đang phân tích các chỉ số...", "Đối chiếu với ngưỡng tham chiếu...", "Xây dựng khuyến nghị cá nhân...", "Hoàn tất báo cáo...", "Sắp xong rồi, chờ một chút nhé..."];
        let messageIndex = 0;
        setLoadingMessage(loadingMessages[messageIndex]);
        const intervalId = setInterval(() => {
            messageIndex = (messageIndex + 1) % loadingMessages.length;
            setLoadingMessage(loadingMessages[messageIndex]);
        }, 3000);

        try {
            const imageParts = await Promise.all(files.map(file => fileToGenerativePart(file)));
            const heightInMeters = parseFloat(height) / 100;
            const bmi = parseFloat(weight) / (heightInMeters * heightInMeters);
            const bmiInfo = getBmiInfo(bmi);

            const prompt = `Phân tích hình ảnh hoặc PDF kết quả xét nghiệm này cho một người ${age} tuổi, giới tính ${gender}, cao ${height} cm, nặng ${weight} kg và có công việc là '${occupation}'. Chỉ số BMI của họ là ${bmi.toFixed(1)}, được phân loại là '${bmiInfo.classification}'. Dựa trên tất cả các thông tin này (kết quả xét nghiệm, tuổi, giới tính, BMI, công việc), hãy tạo các mục sau bằng tiếng Việt:
0. Một đối tượng điểm sức khỏe tổng thể bao gồm: một 'score' (0-100), một 'label' phân loại ngắn (ví dụ: 'Tốt', 'Khá', 'Cần cải thiện'), và một 'explanation' giải thích ngắn gọn cách tính điểm, nêu bật các yếu tố chính đã ảnh hưởng đến nó.
1. Phân tích chỉ số BMI, đưa ra nhận xét ngắn gọn về ý nghĩa của nó.
2. Phân nhóm các chỉ số xét nghiệm vào 5-7 danh mục sức khỏe chính. Với mỗi danh mục:
- Đưa ra một điểm số tổng hợp ('score') từ 1 đến 10.
- Một tóm tắt ngắn gọn ('summary').
- Một 'iconName' phù hợp từ một trong các chuỗi sau: 'HeartPulse', 'ShieldCheck', 'Flame', 'Bone', 'Droplets', 'BrainCircuit', 'Activity'.
- Một 'categoryName' LÀ MỘT MẢNG CÁC CHUỖI, trong đó mỗi chuỗi là một từ riêng lẻ của tên danh mục. Ví dụ: "Kiểm soát Đường huyết" phải trở thành ["Kiểm", "soát", "Đường", "huyết"].
3. Tạo một mảng các chỉ số xét nghiệm chi tiết ('metrics'). Với mỗi chỉ số:
   - Trích xuất tên ('name'), giá trị ('value'), đơn vị ('unit'), và ngưỡng tham chiếu ('referenceRange').
   - Phân loại trạng thái ('classification') một cách CHÍNH XÁC VÀ NGHIÊM NGẶT như sau:
     - Nếu giá trị nằm TRONG KHOẢNG ngưỡng tham chiếu (bao gồm cả hai đầu mút), phân loại là 'Bình thường'.
     - Nếu giá trị VƯỢT QUÁ giới hạn trên của ngưỡng tham chiếu, phân loại là 'Cao'.
     - Nếu giá trị THẤP HƠN giới hạn dưới của ngưỡng tham chiếu, phân loại là 'Thấp'.
     - QUAN TRỌNG: Chỉ sử dụng các giá trị phân loại là 'Cao', 'Thấp', hoặc 'Bình thường'. Không sử dụng các giá trị khác như 'Cận-giới-hạn'.
   - Cung cấp một giải thích ngắn gọn ('explanation') về ý nghĩa của chỉ số, đặc biệt là đối với các chỉ số bất thường.
4. Gợi ý các loại thực phẩm giàu dinh dưỡng để cải thiện các chỉ số này. Với mỗi thực phẩm, hãy gợi ý một trong các siêu thị sau đây để mua: 'Lotte Mart', 'Co.op Food', hoặc 'Bách Hóa Xanh'.`;
            
            const schema = {
                type: Type.OBJECT,
                properties: {
                    overallHealthScore: {
                        type: Type.OBJECT,
                        properties: {
                            score: { type: Type.NUMBER },
                            label: { type: Type.STRING },
                            explanation: { type: Type.STRING }
                        },
                        required: ["score", "label", "explanation"]
                    },
                    bmiAnalysis: { type: Type.OBJECT, properties: { summary: { type: Type.STRING } }, required: ["summary"] },
                    healthAnalysis: { type: Type.OBJECT, properties: { categories: { type: Type.ARRAY, items: { type: Type.OBJECT, properties: { categoryName: { type: Type.ARRAY, items: { type: Type.STRING } }, score: { type: Type.NUMBER }, summary: { type: Type.STRING }, iconName: { type: Type.STRING } }, required: ["categoryName", "score", "summary", "iconName"] } } }, required: ["categories"] },
                    metrics: { type: Type.ARRAY, items: { type: Type.OBJECT, properties: { name: { type: Type.STRING }, value: { type: Type.STRING }, unit: { type: Type.STRING }, referenceRange: { type: Type.STRING }, classification: { type: Type.STRING }, explanation: { type: Type.STRING } }, required: ["name", "value", "unit", "referenceRange", "classification", "explanation"] } },
                    recommendedFoods: { type: Type.ARRAY, items: { type: Type.OBJECT, properties: { foodName: { type: Type.STRING }, benefit: { type: Type.STRING }, servingSuggestion: { type: Type.STRING }, suggestedStore: { type: Type.STRING, enum: ['Lotte Mart', 'Co.op Food', 'Bách Hóa Xanh'] } }, required: ["foodName", "benefit", "servingSuggestion", "suggestedStore"] } },
                },
                required: ["overallHealthScore", "bmiAnalysis", "healthAnalysis", "metrics", "recommendedFoods"]
            };

            const response = await ai.models.generateContent({
                model: 'gemini-2.5-flash',
                contents: [{text: prompt}, ...imageParts],
                config: { responseMimeType: "application/json", responseSchema: schema }
            });
            
            setAnalysisResult(JSON.parse(response.text.trim()));
            setAppView('results');

        } catch (e) {
            console.error(e);
            setError("Đã xảy ra lỗi trong quá trình phân tích. Vui lòng thử lại với tệp rõ ràng hơn hoặc kiểm tra kết nối mạng.");
        } finally {
            setIsLoading(false);
            clearInterval(intervalId);
        }
    };

    const handleSaveResult = () => {
        const newHistoryItem = {
            date: new Date().toISOString(),
            analysis: analysisResult,
            inputs: { age, height, weight, gender, occupation }
        };
        const updatedHistory = [newHistoryItem, ...userHistory];
        setUserHistory(updatedHistory);
        localStorage.setItem(`health_history_${currentUser.email}`, JSON.stringify(updatedHistory));
        alert('Đã lưu kết quả thành công!');
        resetForm();
    };
    
    const handleViewHistoryItem = (item) => {
        setSelectedHistoryItem(item);
    };

    const renderAuthScreen = () => _jsxs("div", { className: "auth-container", children: [_jsxs("div", { className: "auth-box", children: [_jsxs("h2", { children: [_jsx(User, { className: "icon" }), isLogin ? "Đăng nhập" : "Đăng ký"] }), authError && _jsx("p", { className: "auth-error", children: authError }), _jsx("input", { type: "email", value: email, onChange: e => setEmail(e.target.value), placeholder: "Email", "aria-label": "Email" }), _jsx("input", { type: "password", value: password, onChange: e => setPassword(e.target.value), placeholder: "Mật khẩu", "aria-label": "Mật khẩu" }), _jsx("button", { onClick: handleAuth, className: "auth-button", children: isLogin ? "Đăng nhập" : "Đăng ký" }), _jsxs("p", { className: "auth-toggle", onClick: () => { setIsLogin(!isLogin); setAuthError(''); }, children: [isLogin ? "Chưa có tài khoản?" : "Đã có tài khoản?", " ", _jsx("span", { children: isLogin ? "Đăng ký ngay" : "Đăng nhập" })] })] }), _jsx("div", { className: "disclaimer", children: _jsx("b", { children: "Tuyên bố miễn trừ trách nhiệm: Ứng dụng này sử dụng AI để cung cấp thông tin tham khảo và không thay thế cho tư vấn y tế chuyên nghiệp. Luôn tham khảo ý kiến bác sĩ để có chẩn đoán và điều trị chính xác." }) })] });
    
    const handleGeneratePlan = useCallback(async (planType) => {
        const healthDataSource = analysisResult ? 
            { analysis: analysisResult, inputs: { age, height, weight, gender, occupation } } : 
            (userHistory.length > 0 ? userHistory[0] : null);

        if (!healthDataSource) {
            setError("Không tìm thấy dữ liệu sức khỏe. Vui lòng thực hiện phân tích trước.");
            return;
        }
        
        if (!planRequest) {
            setError("Vui lòng nhập yêu cầu của bạn để AI có thể tạo kế hoạch.");
            return;
        }

        setIsGeneratingPlan(true);
        setError(null);

        const { analysis: healthData, inputs: userProfile } = healthDataSource;
        
        const abnormalMetrics = healthData.metrics.filter(m => m.classification !== 'Bình thường' && m.classification !== 'Normal')
            .map(m => `- ${m.name}: ${m.value} ${m.unit} (${m.classification}).`)
            .join('\n');
            
        const healthSummary = `
- **Điểm Sức khỏe Tổng thể:** ${healthData.overallHealthScore.score}/100 (${healthData.overallHealthScore.label})
- **Phân tích BMI:** ${healthData.bmiAnalysis.summary}
- **Các lĩnh vực sức khỏe chính:**
  ${healthData.healthAnalysis.categories.map(c => `- ${c.categoryName.join(' ')}: Điểm ${c.score}/10. Tóm tắt: ${c.summary}`).join('\n')}
- **Các chỉ số bất thường cần lưu ý:**
  ${abnormalMetrics || "Không có chỉ số nào bất thường."}
- **Thông tin người dùng:** Tuổi: ${userProfile.age}, Giới tính: ${userProfile.gender}, Công việc: ${userProfile.occupation}
`;

        let prompt = '';
        let schema = {};

        if (planType === 'menu') {
            prompt = `Bạn là một chuyên gia dinh dưỡng AI. Dựa trên báo cáo sức khỏe chi tiết và yêu cầu của người dùng dưới đây, hãy tạo một kế hoạch thực đơn được cá nhân hóa.

**Báo cáo sức khỏe của người dùng:**
${healthSummary}

**Yêu cầu của người dùng về kế hoạch (QUAN TRỌNG NHẤT VÀ PHẢI TUÂN THEO 100%):**
"${planRequest}"

**QUY TẮC BẮT BUỘC:**
1.  **SỐ LƯỢNG NGÀY LÀ TUYỆT ĐỐI:** Phân tích kỹ "${planRequest}". Bạn chỉ được phép tạo kế hoạch cho CHÍNH XÁC số lượng ngày mà người dùng yêu cầu.
    *   VÍ DỤ 1: Nếu người dùng yêu cầu "thực đơn cho ngày mai", bạn CHỈ được trả về JSON với MỘT đối tượng duy nhất.
    *   VÍ DỤ 2: Nếu người dùng yêu cầu "kế hoạch 3 ngày", bạn CHỈ được trả về MỘT mảng có ĐÚNG 3 đối tượng.
2.  **KHÔNG TỰ Ý THÊM NGÀY:** TUYỆT ĐỐI KHÔNG được thêm bất kỳ ngày nào khác nếu không được yêu cầu.
3.  **HOÀN THIỆN CÁC BỮA ĂN:** Kể cả khi người dùng chỉ yêu cầu một loại bữa ăn (ví dụ: chỉ bữa tối), bạn VẪN PHẢI cung cấp đủ các trường 'breakfast', 'lunch', và 'dinner'. Đối với các bữa ăn không được yêu cầu, hãy điền một ghi chú hợp lý vào trường 'notes', ví dụ như "Theo lựa chọn của người dùng" và để 'dishName' là "Không yêu cầu".
4.  **NỘI DUNG KẾ HOẠCH:** Kế hoạch phải được thiết kế để giải quyết các nhu cầu sức khỏe cụ thể được nêu bật trong báo cáo và phù hợp với công việc của họ. Với mỗi bữa ăn, cung cấp 'dishName' và 'notes'. Bao gồm một 'dailyTip' thiết thực cho mỗi ngày.
5.  **ĐỊNH DẠNG NGÀY:** Đối với trường 'day', hãy sử dụng tên ngày cụ thể (ví dụ: "Thứ Hai") nếu được yêu cầu, nếu không hãy sử dụng định dạng "Ngày 1", "Ngày 2", v.v.
6.  **CHỈ TRẢ LỜI BẰNG JSON.**`;


            schema = {
                type: Type.ARRAY,
                items: { type: Type.OBJECT, properties: { day: { type: Type.STRING }, breakfast: { type: Type.OBJECT, properties: { dishName: { type: Type.STRING }, notes: { type: Type.STRING } }, required: ["dishName", "notes"] }, lunch: { type: Type.OBJECT, properties: { dishName: { type: Type.STRING }, notes: { type: Type.STRING } }, required: ["dishName", "notes"] }, dinner: { type: Type.OBJECT, properties: { dishName: { type: Type.STRING }, notes: { type: Type.STRING } }, required: ["dishName", "notes"] }, dailyTip: { type: Type.STRING } }, required: ["day", "breakfast", "lunch", "dinner", "dailyTip"] }
            };
            setGeneratedMealPlan(null);
        } else if (planType === 'workout') {
             prompt = `Bạn là một huấn luyện viên thể hình AI chuyên nghiệp. Nhiệm vụ của bạn là tạo một kế hoạch tập luyện được cá nhân hóa, TUÂN THỦ TUYỆT ĐỐI yêu cầu của người dùng.

**Báo cáo sức khỏe của người dùng:**
${healthSummary}

**Yêu cầu của người dùng về kế hoạch (QUAN TRỌNG NHẤT VÀ PHẢI TUÂN THEO 100%):**
"${planRequest}"

**QUY TẮC BẮT BUỘC:**
1.  **SỐ LƯỢNG NGÀY LÀ TUYỆT ĐỐI:** Phân tích kỹ "${planRequest}". Bạn chỉ được phép tạo kế hoạch cho CHÍNH XÁC những ngày và số lượng ngày mà người dùng yêu cầu.
    *   VÍ DỤ 1: Nếu người dùng yêu cầu "chiều thứ 3", bạn CHỈ được trả về JSON với MỘT đối tượng duy nhất cho "Thứ Ba".
    *   VÍ DỤ 2: Nếu người dùng yêu cầu "kế hoạch 3 ngày", bạn CHỈ được trả về MỘT mảng có ĐÚNG 3 đối tượng.
    *   VÍ DỤ 3: Nếu người dùng yêu cầu "T2, T4, T6", bạn CHỈ được trả về MỘT mảng có ĐÚNG 3 đối tượng cho các ngày đó.
2.  **KHÔNG TỰ Ý THÊM NGÀY:** TUYỆT ĐỐI KHÔNG được thêm bất kỳ ngày nào khác, kể cả ngày nghỉ, nếu người dùng không yêu cầu một kế hoạch theo cấu trúc cả tuần. Chỉ thêm ngày nghỉ nếu người dùng yêu cầu rõ ràng như "kế hoạch cho cả tuần, tập 3 ngày".
3.  **ĐỊNH DẠNG NGÀY NGHỈ:** Nếu một ngày được xác định là ngày nghỉ, hãy đặt 'workoutFocus' thành "Ngày nghỉ" và 'exercises' phải là một mảng rỗng \`[]\`.
4.  **ĐỊNH DẠNG ĐẦU RA (JSON):**
    - Trả về một mảng các đối tượng.
    - Mỗi đối tượng phải có: 'day', 'workoutFocus', 'exercises' (mảng), và 'dailyFitnessTip'.
5.  **CHỈ TRẢ LỜI BẰNG JSON.**`;


            schema = {
                type: Type.ARRAY,
                items: {
                    type: Type.OBJECT,
                    properties: {
                        day: { type: Type.STRING },
                        workoutFocus: { type: Type.STRING },
                        exercises: { type: Type.ARRAY, items: { type: Type.OBJECT, properties: { name: { type: Type.STRING }, sets: { type: Type.STRING }, reps: { type: Type.STRING }, notes: { type: Type.STRING } }, required: ["name", "sets", "reps", "notes"] } },
                        dailyFitnessTip: { type: Type.STRING }
                    },
                    required: ["day", "workoutFocus", "exercises", "dailyFitnessTip"]
                }
            };
            setGeneratedWorkoutPlan(null);
        }

        try {
            const response = await ai.models.generateContent({
                model: 'gemini-2.5-flash',
                contents: prompt,
                config: { responseMimeType: "application/json", responseSchema: schema }
            });
            const result = JSON.parse(response.text.trim());
            if (planType === 'menu') {
                setGeneratedMealPlan(result);
            } else {
                setGeneratedWorkoutPlan(result);
            }
        } catch (e) {
            console.error(e);
            setError("Đã xảy ra lỗi khi tạo kế hoạch. Vui lòng thử lại.");
        } finally {
            setIsGeneratingPlan(false);
        }
    }, [analysisResult, userHistory, age, height, weight, gender, occupation, planRequest]);
    
    const renderContent = () => {
        switch (appView) {
            case 'results':
                if (isLoading) return _jsxs("div", { className: "loading-container", children: [_jsx("div", { className: "spinner" }), _jsx("p", { children: loadingMessage })] });
                if (error) return _jsxs("div", { className: "error-container", children: [_jsx("p", { children: error }), _jsx("button", { onClick: resetForm, className: "action-button", children: "Thử lại" })] });
                if (analysisResult) return _jsx(AnalysisResultView, { resultData: { analysis: analysisResult, date: new Date().toISOString(), inputs: { age, height, weight, gender, occupation } }, isHistory: false, theme: theme, setSelectedHistoryItem: setSelectedHistoryItem, handleSaveResult: handleSaveResult, resetForm: resetForm });
                return null;
            
            case 'history':
                return _jsxs("div", { className: "history-container", children: [!selectedHistoryItem && _jsxs("div", { children: [_jsxs("h2", { children: [_jsx(History, { className: "icon" }), "Lịch sử Sức khỏe"] }), userHistory.length > 0 ? _jsxs("div", { children: [_jsx("p", { children: "Chọn một điểm trên biểu đồ để xem lại chi tiết phân tích." }), _jsx("div", { className: "history-chart-container", children: _jsx(HistoryChart, { history: userHistory, onPointClick: handleViewHistoryItem, theme: theme }) })] }) : _jsx("p", { children: "Chưa có lịch sử nào được lưu." })] }), selectedHistoryItem && _jsx(AnalysisResultView, { resultData: selectedHistoryItem, isHistory: true, theme: theme, setSelectedHistoryItem: setSelectedHistoryItem, handleSaveResult: handleSaveResult, resetForm: resetForm })] });
            
            case 'menuPlanner':
                return _jsx(PlanGeneratorView, { planType: "menu", planRequest: planRequest, onPlanRequestChange: setPlanRequest, handleGeneratePlan: handleGeneratePlan, isGeneratingPlan: isGeneratingPlan, error: error, generatedMealPlan: generatedMealPlan, generatedWorkoutPlan: generatedWorkoutPlan, analysisResult: analysisResult, userHistory: userHistory });

            case 'workoutPlanner':
                return _jsx(PlanGeneratorView, { planType: "workout", planRequest: planRequest, onPlanRequestChange: setPlanRequest, handleGeneratePlan: handleGeneratePlan, isGeneratingPlan: isGeneratingPlan, error: error, generatedMealPlan: generatedMealPlan, generatedWorkoutPlan: generatedWorkoutPlan, analysisResult: analysisResult, userHistory: userHistory });

            case 'form':
            default:
                return _jsxs("div", { className: "form-container", children: [_jsx("input", { type: "file", ref: fileInputRef, onChange: handleFileChange, style: { display: 'none' }, accept: "image/*,application/pdf", multiple: true }), _jsxs("div", { className: "form-grid", children: [_jsxs("div", { className: "form-group", children: [_jsx("label", { htmlFor: "age", children: "Tuổi" }), _jsx("input", { type: "number", id: "age", value: age, onChange: (e) => setAge(e.target.value), placeholder: "VD: 30", min: "1" })] }), _jsxs("div", { className: "form-group", children: [_jsx("label", { htmlFor: "height", children: "Chiều cao (cm)" }), _jsx("input", { type: "number", id: "height", value: height, onChange: (e) => setHeight(e.target.value), placeholder: "VD: 175", min: "1" })] }), _jsxs("div", { className: "form-group", children: [_jsx("label", { htmlFor: "weight", children: "Cân nặng (kg)" }), _jsx("input", { type: "number", id: "weight", value: weight, onChange: (e) => setWeight(e.target.value), placeholder: "VD: 70", min: "1" })] }), _jsxs("div", { className: "form-group", children: [_jsx("label", { children: "Giới tính" }), _jsxs("div", { className: "gender-options", children: [_jsxs("div", { className: "gender-option", children: [_jsx("input", { type: "radio", id: "male", name: "gender", value: "Nam", checked: gender === 'Nam', onChange: (e) => setGender(e.target.value) }), _jsxs("label", { htmlFor: "male", children: [_jsx(Mars, { className: "icon" }), "Nam"] })] }), _jsxs("div", { className: "gender-option", children: [_jsx("input", { type: "radio", id: "female", name: "gender", value: "Nữ", checked: gender === 'Nữ', onChange: (e) => setGender(e.target.value) }), _jsxs("label", { htmlFor: "female", children: [_jsx(Venus, { className: "icon" }), "Nữ"] })] })] })] }), _jsxs("div", { className: "form-group full-width", children: [_jsxs("label", { htmlFor: "occupation", children: [_jsx(Briefcase, { size: 16 }), "Công việc hiện tại"] }), _jsx("input", { type: "text", id: "occupation", value: occupation, onChange: (e) => setOccupation(e.target.value), placeholder: "VD: Nhân viên văn phòng" })] }), _jsxs("div", { className: "file-upload-area full-width", onClick: handleAreaClick, children: [_jsx(UploadCloud, { className: "icon" }), _jsx("p", { children: "Nhấn để tải lên hoặc kéo thả tệp" }), _jsx("span", { children: "Hỗ trợ nhiều tệp Ảnh hoặc PDF" }), files.length > 0 && _jsx("div", { className: "file-list", children: files.map(f => _jsx("p", { className: "file-name", children: f.name }, f.name)) })] }), _jsxs("button", { onClick: handleAnalysis, disabled: !isFormValid || isLoading, className: "submit-button full-width", children: [_jsx(Send, {}), isLoading ? "Đang xử lý..." : "Phân tích"] })] })] });
        }
    };

    return _jsxs(React.Fragment, {
        children: [
            _jsx("button", { 
                onClick: toggleTheme, 
                className: "global-theme-toggle", 
                "aria-label": "Toggle theme", 
                children: theme === 'light' ? _jsx(Moon, { size: 20 }) : _jsx(Sun, { size: 20 }) 
            }),
            view === 'auth' 
                ? renderAuthScreen() 
                : _jsxs("div", { 
                    className: "container", 
                    children: [
                        _jsx(AppHeader, { appView: appView, setAppView: setAppView, setSelectedHistoryItem: setSelectedHistoryItem, resetPlans: resetPlans, handleSignOut: handleSignOut }), 
                        renderContent(), 
                        !['history', 'menuPlanner', 'workoutPlanner'].includes(appView) && _jsx("div", { 
                            className: "disclaimer", 
                            children: _jsx("b", { 
                                children: "Tuyên bố miễn trừ trách nhiệm: Ứng dụng này sử dụng AI để cung cấp thông tin tham khảo và không thay thế cho tư vấn y tế chuyên nghiệp. Luôn tham khảo ý kiến bác sĩ để có chẩn đoán và điều trị chính xác." 
                            }) 
                        })
                    ] 
                })
        ]
    });
};

const root = createRoot(document.getElementById('root'));
root.render(_jsx(React.StrictMode, { children: _jsx(App, {}) }));
