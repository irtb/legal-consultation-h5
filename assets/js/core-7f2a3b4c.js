/**
 * Legal Consultation System - Core Engine (企微专用版)
 * Version: 2.0.4
 * Build: 7f2a3b4c
 */

(function(global) {
    'use strict';

    // 状态管理
    const AppState = (function() {
        const _private = {
            sessionId: 0,
            currentStepIndex: -1,
            userInputData: {},
            eventLog: '',
            processingPhase: 0
        };

        return {
            get: (key) => _private[key],
            set: (key, value) => { _private[key] = value; },
            increment: (key) => { _private[key]++; },
            reset: () => {
                _private.currentStepIndex = -1;
                _private.userInputData = {};
                _private.eventLog = '';
            }
        };
    })();

    // 数据配置
    const ConsultationFlowData = [
        {
            stageKey: "debt_type_assessment",
            promptText: "请问您目前是哪种债务逾期？",
            displayColumns: 1,
            selectionOptions: [
                { optionId: "DT001", labelText: "信用卡或网贷债务" },
                { optionId: "DT002", labelText: "企业贷债务" },
                { optionId: "DT003", labelText: "银行信用贷债务" },
                { optionId: "DT004", labelText: "个人借款债务" },
                { optionId: "DT005", labelText: "房贷或车贷债务" }
            ]
        },
        {
            stageKey: "overdue_status_check",
            promptText: "请问您目前的逾期状态？",
            displayColumns: 1,
            selectionOptions: [
                { optionId: "OS001", labelText: "还未逾期" },
                { optionId: "OS002", labelText: "逾期1个月内" },
                { optionId: "OS003", labelText: "逾期1-3个月" },
                { optionId: "OS004", labelText: "逾期3个月-1年" },
                { optionId: "OS005", labelText: "逾期1年以上" }
            ]
        },
        {
            stageKey: "financial_situation",
            promptText: "请问您目前的经济状况？",
            displayColumns: 1,
            selectionOptions: [
                { optionId: "FS001", labelText: "除去生活开支，有多余的钱可偿还债务，想回到生活正轨" },
                { optionId: "FS002", labelText: "想避免打扰，目前有一点收入，想要停止催收和咨询下对应还款方案" },
                { optionId: "FS003", labelText: "没有什么收入，也没有意愿还款" }
            ]
        }
    ];

    // DOM 操作引擎
    const DOMEngine = {
        cache: {},
        
        init: function() {
            this.cache.workflowPanel = $('#interactive-workflow-panel');
            this.cache.stageWrapper = $('.stage-wrapper');
            this.cache.threadDisplay = $('#msg-stream-container');
            this.cache.conversationThread = $('#conversation-thread');
        },

        scrollToLatestMessage: function() {
            const self = this;
            setTimeout(() => {
                const container = self.cache.workflowPanel;
                
                if (container.length) {
                    const targetScroll = container[0].scrollHeight - container[0].clientHeight;
                    
                    container.animate({
                        scrollTop: targetScroll
                    }, 1000, 'swing');
                }
            }, 800);
        }
    };

    // 时间格式化
    const TimeFormatter = {
        format: function(dateInstance, pattern) {
            pattern = pattern || "yyyy-MM-dd";
            
            const components = {
                "M+": dateInstance.getMonth() + 1,
                "d+": dateInstance.getDate(),
                "h+": dateInstance.getHours(),
                "m+": dateInstance.getMinutes(),
                "s+": dateInstance.getSeconds(),
                "q+": Math.floor((dateInstance.getMonth() + 3) / 3),
                S: dateInstance.getMilliseconds()
            };
            
            if (/(y+)/.test(pattern)) {
                pattern = pattern.replace(
                    RegExp.$1,
                    (dateInstance.getFullYear() + "").substr(4 - RegExp.$1.length)
                );
            }
            
            for (let key in components) {
                if (new RegExp("(" + key + ")").test(pattern)) {
                    pattern = pattern.replace(
                        RegExp.$1,
                        RegExp.$1.length === 1 ? components[key] : 
                        ("00" + components[key]).substr(("" + components[key]).length)
                    );
                }
            }
            
            return pattern;
        },
        
        getCurrentTime: function() {
            return this.format(new Date(), "hh:mm");
        }
    };

    // UI 渲染引擎
    const UIRenderer = {
        renderQuestionBlock: function(questionData) {
            const timestamp = TimeFormatter.getCurrentTime();
            
            let markup = '<div class="bot-response-block anim-reveal">';
            markup += '    <div class="sender-portrait">';
            markup += '        <img src="./media/images/advisor-portrait-001.jpg" alt="律师">';
            markup += '    </div>';
            markup += '    <div class="message-container">';
            markup += '        <div class="message-header">';
            markup += '            <span class="sender-name">刘律师 ' + (typeof isShenhe !== 'undefined' && isShenhe ? "劳动法顾问" : "法律顾问") + '</span>';
            markup += '            <span class="timestamp">' + timestamp + '</span>';
            markup += '        </div>';
            markup += '        <div class="content-bubble choice-selection-bubble">';
            markup += '            <p>' + questionData.promptText + '</p>';
            markup += '            <div class="choice-options-list">';

            for (let i = 0; i < questionData.selectionOptions.length; i++) {
                const option = questionData.selectionOptions[i];
                markup += '<div class="selectable-choice" data-choice-value="' + option.labelText + '">' + option.labelText + '</div>';
            }

            markup += '            </div>';
            markup += '        </div>';
            markup += '    </div>';
            markup += '</div>';

            $('#conversation-thread').append(markup);
            // EventBinder.bindChoiceEvents();
        },

        renderUserResponse: function(responseText) {
            let markup = '<div class="user-input-block">';
            markup += '    <div class="user-text-content">';
            markup += responseText;
            markup += '    </div>';
            markup += '</div>';
            $('#conversation-thread').append(markup);
        },

        renderUnableToProcessMessage: function(messageContent) {
            const timestamp = TimeFormatter.getCurrentTime();
            
            let markup = '<div class="bot-response-block anim-reveal">';
            markup += '   <div class="sender-portrait">';
            markup += '       <img src="./media/images/advisor-portrait-001.jpg" alt="律师">';
            markup += '   </div>';
            markup += '   <div class="message-container">';
            markup += '       <div class="message-header">';
            markup += '           <span class="sender-name">刘律师 ' + (typeof isShenhe !== 'undefined' && isShenhe ? "劳动法顾问" : "法律顾问") + '</span>';
            markup += '           <span class="timestamp">' + timestamp + '</span>';
            markup += '       </div>';
            markup += '       <div class="content-bubble" style="display:block">';
            markup += messageContent;
            markup += '       </div>';
            markup += '   </div>';
            markup += '</div>';
            
            $('#conversation-thread').append(markup);
            DOMEngine.scrollToLatestMessage();
        },

        // // ✅ 直接显示咨询建议，移除"分析中"
        // renderFinalConsultationResult: function() {
        //     const timestamp = TimeFormatter.getCurrentTime();

        //     let markup = '<div class="bot-response-block anim-reveal">';
        //     markup += '   <div class="sender-portrait">';
        //     markup += '       <img src="./media/images/advisor-portrait-001.jpg" alt="律师">';
        //     markup += '   </div>';
        //     markup += '   <div class="message-container">';
        //     markup += '       <div class="message-header">';
        //     markup += '           <span class="sender-name">刘律师 ' + (typeof isShenhe !== 'undefined' && isShenhe ? "劳动法顾问" : "法律顾问") + '</span>';
        //     markup += '           <span class="timestamp">' + timestamp + '</span>';
        //     markup += '       </div>';
        //     markup += '       <div class="content-bubble" id="consultation-recommendation">';
        //     markup += '<p style="margin-bottom: 0.5rem;">我们已经了解您的基本情况，因为当前是临时咨询，<strong><span style="color: rgb(255, 0, 0);">请您添加企业微信，我为您安排律师进一步了解您的情况，为您制定一套还款方案。</span></strong>点击咨询，在线律师</p>';
        //     markup += '<p style="margin-bottom: 0.5rem;">(名额有限，5分钟内添加有效)</p>';
        //     markup += '       <div>';
        //     markup += '           <div class="zaax-click consultation-cta-button" data-ticket="" style="margin-bottom:5px">企微咨询</div>';
        //     markup += '       </div>';
        //     markup += '   </div>';
        //     markup += '</div>';

        //     $('#conversation-thread').append(markup);
        //     DOMEngine.scrollToLatestMessage();

        //     // ✅ 简化延迟
        //     setTimeout(function() {
        //         $('#floating-consultation-widget').fadeIn();
                
        //         if (typeof isChenyang !== 'undefined' && !isChenyang) {
        //             window.history.pushState({title: "consultation", url: "#"}, '', "#");
        //         }
                
        //         ZaaxCompatibility.refreshBindings();
        //     }, 400);
        // }

        // 自定义时间
        renderFinalConsultationResult: function() {
            const timestamp = TimeFormatter.getCurrentTime();

            let markup = '<div class="bot-response-block anim-reveal">';
            markup += '   <div class="sender-portrait">';
            markup += '       <img src="./media/images/advisor-portrait-001.jpg" alt="律师">';
            markup += '   </div>';
            markup += '   <div class="message-container">';
            markup += '       <div class="message-header">';
            markup += '           <span class="sender-name">刘律师 ' + (typeof isShenhe !== 'undefined' && isShenhe ? "劳动法顾问" : "法律顾问") + '</span>';
            markup += '           <span class="timestamp">' + timestamp + '</span>';
            markup += '       </div>';
            markup += '       <div class="content-bubble processing-indicator" id="analysis-in-progress" style="display:block">';
            markup += '           您的信息正在分析中...<span></span>';
            markup += '       </div>';
            markup += '       <div class="content-bubble" id="consultation-recommendation" style="display:none">';
            markup += '<p style="margin-bottom: 0.5rem;">我们已经了解您的基本情况，因为当前是临时咨询，<strong><span style="color: rgb(255, 0, 0);">请您添加企业微信，我为您安排律师进一步了解您的情况，为您制定一套还款方案。</span></strong>点击咨询，在线律师</p>';
            markup += '<p style="margin-bottom: 0.5rem;">(名额有限，5分钟内添加有效)</p>';
            markup += '       <div>';
            markup += '           <div class="zaax-click consultation-cta-button" data-ticket="" style="margin-bottom:5px">企微咨询</div>';
            markup += '       </div>';
            markup += '   </div>';
            markup += '</div>';

            $('#conversation-thread').append(markup);

            // ✅ 自定义各个时间
            const ANALYSIS_DELAY = 1000;        // "分析中"显示时长
            const FADEOUT_SPEED = 300;         // fadeOut速度
            const BUTTON_DELAY = 500;          // 按钮弹出延迟
            const SCROLL_DELAY = 300;          // 滚动延迟

            setTimeout(function() {
                $('#analysis-in-progress').fadeOut(FADEOUT_SPEED, function() {
                    $('#consultation-recommendation').fadeIn();
                    DOMEngine.scrollToLatestMessage();

                    setTimeout(function() {
                        $('#floating-consultation-widget').fadeIn();
                    }, BUTTON_DELAY);

                    setTimeout(function() {
                        DOMEngine.scrollToLatestMessage();
                        if (typeof isChenyang !== 'undefined' && !isChenyang) {
                            // window.history.pushState({title: "consultation", url: "#"}, '', "#");
                        }
                        ZaaxCompatibility.refreshBindings();
                    }, SCROLL_DELAY);
                });
            }, ANALYSIS_DELAY);
        }
    };

    // 延迟执行
    const AsyncHelper = {
        delay: function(milliseconds) {
            return new Promise(function(resolve) {
                setTimeout(resolve, milliseconds);
            });
        }
    };

    // 交互处理
    const InteractionHandler = {
        handleChoiceSelection: function() {
            const $clickedElement = $(this);
            const selectedText = $clickedElement.text();
            
            if ($clickedElement.hasClass('processing')) return;
            $clickedElement.addClass('processing');
            
            if (AppState.get('currentStepIndex') >= 0 && 
                AppState.get('currentStepIndex') < ConsultationFlowData.length) {
                const currentStageKey = ConsultationFlowData[AppState.get('currentStepIndex')].stageKey;
                const currentData = AppState.get('userInputData');
                currentData[currentStageKey] = selectedText;
                AppState.set('userInputData', currentData);
            }

            $clickedElement.parent().hide();
            AnalyticsModule.recordEvent(selectedText);
            
            UIRenderer.renderUserResponse(selectedText);

            AppState.increment('currentStepIndex');

            setTimeout(function() {
                if (AppState.get('currentStepIndex') < ConsultationFlowData.length) {
                    if (selectedText === '5万以下') {
                        InteractionHandler.handleSpecialCase('很抱歉，您的债务金额过低，协商还款有一定的成本，对您来说并不是合理的选择，建议您自行还款。');
                    } else if (selectedText === '借款，贷款') {
                        InteractionHandler.handleSpecialCase('很抱歉，借款，贷款业务暂时无法受理。');
                    } else if (selectedText === '个人借款债务' || selectedText === '房贷或车贷债务') {
                        InteractionHandler.handleSpecialCase('很抱歉，个人借款纠纷/房贷车贷暂时无法受理。');
                    } else if (selectedText === '逾期1年以上') {
                        InteractionHandler.handleSpecialCase('您的逾期时间过久，暂时无法受理，建议您可先专心工作后咨询。');
                    } else {
                        UIRenderer.renderQuestionBlock(
                            ConsultationFlowData[AppState.get('currentStepIndex')]
                        );
                        DOMEngine.scrollToLatestMessage();  // 在这里统一滚动
                    }
                } else {
                    if (selectedText === '没有什么收入，也没有意愿还款') {
                        InteractionHandler.handleSpecialCase('为了您能够重回生活正轨，帮助您进行债务协商也是需要您正常进行偿还，在您还没有足够的经济能力还款之前，建议先努力工作，没有还款意愿也无法进行协商');
                        return;
                    }
                    DataSubmitter.submitUserData('');
                    UIRenderer.renderFinalConsultationResult();
                }
                $('#legal-disclaimer').hide();
            }, 400);
        },

        handleSpecialCase: function(message) {
            setTimeout(function() {
                UIRenderer.renderUnableToProcessMessage(message);
                // 移除这里的滚动调用
            }, 400);
        }
    };

    // 好多粉兼容层
    const ZaaxCompatibility = {
        refreshBindings: function() {
            if (typeof window.zaax !== 'undefined') {
                if (typeof window.zaax.init === 'function') window.zaax.init();
                if (typeof window.zaax.rebind === 'function') window.zaax.rebind();
                if (typeof window.zaax.refresh === 'function') window.zaax.refresh();
                if (typeof window.zaax.scan === 'function') window.zaax.scan();
            }
            
            try {
                const event = new CustomEvent('zaax:refresh', { 
                    detail: { source: 'legal-consultation-app', timestamp: Date.now() } 
                });
                document.dispatchEvent(event);
            } catch (e) {}
            
            setTimeout(function() {
                if (typeof window.zaax !== 'undefined' && typeof window.zaax.init === 'function') {
                    window.zaax.init();
                }
            }, 300);
        },
        
        waitForZaaxReady: function(callback, maxAttempts) {
            maxAttempts = maxAttempts || 50;
            let attempts = 0;
            
            const checkInterval = setInterval(function() {
                attempts++;
                
                if (typeof window.zaax !== 'undefined') {
                    clearInterval(checkInterval);
                    if (callback) callback();
                } else if (attempts >= maxAttempts) {
                    clearInterval(checkInterval);
                    if (callback) callback();
                }
            }, 100);
        },
        
        observeDOMChanges: function() {
            const targetNode = document.getElementById('conversation-thread');
            if (!targetNode) return;
            
            const observer = new MutationObserver(function(mutations) {
                let hasNewZaaxElements = false;
                
                mutations.forEach(function(mutation) {
                    if (mutation.addedNodes.length > 0) {
                        mutation.addedNodes.forEach(function(node) {
                            if (node.nodeType === 1) {
                                if (node.classList && node.classList.contains('zaax-click')) {
                                    hasNewZaaxElements = true;
                                } else if (node.querySelector && node.querySelector('.zaax-click')) {
                                    hasNewZaaxElements = true;
                                }
                            }
                        });
                    }
                });
                
                if (hasNewZaaxElements) {
                    setTimeout(function() {
                        ZaaxCompatibility.refreshBindings();
                    }, 100);
                }
            });
            
            observer.observe(targetNode, {
                childList: true,
                subtree: true
            });
        }
    };

    // 事件绑定
    const EventBinder = {
        bindChoiceEvents: function() {
            // $('.selectable-choice').off('click').on('click', InteractionHandler.handleChoiceSelection);
            $('#conversation-thread').off('click', '.selectable-choice')
            .on('click', '.selectable-choice', InteractionHandler.handleChoiceSelection);
        },

        bindModalEvents: function() {
            $('#modal-backdrop-layer').on('click', function() {
                $('#modal-backdrop-layer').hide();
                $('.modal-popup').hide();
            });

            $('#dismiss-exit-prompt').on('click', function() {
                $('#modal-backdrop-layer').hide();
                $('.modal-popup').hide();
            });

            // if (typeof isChenyang !== 'undefined' && !isChenyang) {
            //     window.addEventListener("popstate", function(e) {
            //         if ($("#exit-confirmation-modal").css('display') !== "block") {
            //             $("#modal-backdrop-layer").show();
            //             $("#exit-confirmation-modal").show();
            //         }
            //     }, false);
            // }

            // 企微跳转确认（由zaaxstat.js处理，这里只是关闭弹窗）
            $('#confirm-enterprise-redirect').on('click', function() {
                $('#enterprise-redirect-modal').hide();
            });
        },

        initializeAllEvents: function() {
            this.bindChoiceEvents();
            this.bindModalEvents();
            
            ZaaxCompatibility.waitForZaaxReady(function() {
                ZaaxCompatibility.refreshBindings();
                ZaaxCompatibility.observeDOMChanges();
            });
        }
    };

    // 数据提交
    const DataSubmitter = {
        submitUserData: function(phoneNumber) {
            const submissionData = AppState.get('userInputData');
            console.log('[提交数据]', submissionData);
        }
    };

    // 分析追踪
    const AnalyticsModule = {
        recordEvent: function(eventData) {
            let currentLog = AppState.get('eventLog');
            
            if (currentLog === '') {
                currentLog = eventData;
            } else {
                currentLog += ';' + eventData;
            }
            
            AppState.set('eventLog', currentLog);
            AppState.increment('processingPhase');
        }
    };

    // 响应式布局
    const ResponsiveLayout = {
        initialize: function() {
            let screenWidth = (document.body && document.body.clientWidth) || 
                            document.getElementsByTagName("html")[0].offsetWidth;
            screenWidth = Math.min(540, screenWidth);
            const baseFontSize = screenWidth / 20;
            
            document.getElementsByTagName("html")[0].setAttribute(
                "style",
                "font-size:" + baseFontSize + "px;background-color:rgb(253, 251, 248)"
            );
        }
    };

    // 应用初始化
    const Application = {
        initialize: function() {
            ResponsiveLayout.initialize();
            DOMEngine.init();
            EventBinder.initializeAllEvents();
            
            setInterval(function() {
                $('.pulse-effect').toggleClass('btn-scale-effect');
            }, 250);
        }
    };

    global.LegalConsultationApp = {
        start: Application.initialize,
        state: AppState,
        zaax: ZaaxCompatibility,
        version: '2.0.4'
    };

    $(document).ready(function() {
        Application.initialize();
    });

})(window);
