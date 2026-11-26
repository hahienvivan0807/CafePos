(() => {
    const workspaceGrid = document.getElementById("workspace-grid");
    const toggleSummaryBtn = document.getElementById("toggle-summary-btn");
    const collapseSummaryBtn = document.getElementById("collapse-summary-btn");
    const tabButtons = Array.from(document.querySelectorAll(".tab-btn"));
    const tabPanels = Array.from(document.querySelectorAll(".tab-panel"));
    const searchInput = document.getElementById("search-input");
    const filterButtons = Array.from(document.querySelectorAll(".filter-pill"));

    const toast = document.getElementById("save-error-toast");
    const toastMessage = document.getElementById("toast-message");
    const toastRetryBtn = document.getElementById("toast-retry-btn");
    const toastCloseBtn = document.getElementById("toast-close-btn");

    let activeFilter = "all";
    let pendingRetryAction = null;

    // Khôi phục trạng thái thu gọn panel Tóm tắt dự án nếu người dùng đã chọn trước đó
    const SUMMARY_KEY = "cafePosTracker.summaryCollapsed";
    function setSummaryCollapsed(collapsed) {
        if (!workspaceGrid || !toggleSummaryBtn) return;
        workspaceGrid.classList.toggle("is-summary-collapsed", collapsed);
        toggleSummaryBtn.setAttribute("aria-expanded", collapsed ? "false" : "true");
        try {
            localStorage.setItem(SUMMARY_KEY, collapsed ? "1" : "0");
        } catch {
            // Bỏ qua nếu localStorage bị chặn
        }
    }

    try {
        if (localStorage.getItem(SUMMARY_KEY) === "1") {
            setSummaryCollapsed(true);
        }
    } catch {
        // Ignore
    }

    toggleSummaryBtn?.addEventListener("click", () => {
        const isCollapsed = workspaceGrid.classList.contains("is-summary-collapsed");
        setSummaryCollapsed(!isCollapsed);
    });

    collapseSummaryBtn?.addEventListener("click", () => {
        setSummaryCollapsed(true);
        toggleSummaryBtn?.focus();
    });

    // Chuyển tab
    function activateTab(groupCode) {
        tabButtons.forEach((btn) => {
            const isSelected = btn.dataset.groupCode === groupCode;
            btn.classList.toggle("is-active", isSelected);
            btn.setAttribute("aria-selected", isSelected ? "true" : "false");
        });

        tabPanels.forEach((panel) => {
            const isSelected = panel.dataset.groupCode === groupCode;
            panel.classList.toggle("is-active", isSelected);
            panel.hidden = !isSelected;
        });

        applyFilters();
    }

    tabButtons.forEach((btn, idx) => {
        btn.addEventListener("click", () => activateTab(btn.dataset.groupCode));
        btn.addEventListener("keydown", (e) => {
            if (e.key === "ArrowRight") {
                e.preventDefault();
                const next = tabButtons[(idx + 1) % tabButtons.length];
                next.focus();
                activateTab(next.dataset.groupCode);
            } else if (e.key === "ArrowLeft") {
                e.preventDefault();
                const prev = tabButtons[(idx - 1 + tabButtons.length) % tabButtons.length];
                prev.focus();
                activateTab(prev.dataset.groupCode);
            }
        });
    });

    // Tìm kiếm & lọc trạng thái
    function applyFilters() {
        const query = (searchInput?.value || "").trim().toLowerCase();
        const activePanel = tabPanels.find((p) => !p.hidden);
        if (!activePanel) return;

        const cards = Array.from(activePanel.querySelectorAll(".task-card"));
        let visibleCount = 0;

        cards.forEach((card) => {
            const isCompleted = card.dataset.completed === "true";
            const matchesFilter =
                activeFilter === "all" ||
                (activeFilter === "completed" && isCompleted) ||
                (activeFilter === "pending" && !isCompleted);

            const haystack = card.dataset.search || "";
            const matchesSearch = !query || haystack.includes(query);

            const visible = matchesFilter && matchesSearch;
            card.hidden = !visible;
            if (visible) visibleCount++;
        });

        const emptyState = activePanel.querySelector(".empty-state");
        if (emptyState) {
            emptyState.hidden = visibleCount > 0;
        }
    }

    searchInput?.addEventListener("input", applyFilters);

    filterButtons.forEach((btn) => {
        btn.addEventListener("click", () => {
            activeFilter = btn.dataset.filter || "all";
            filterButtons.forEach((b) => b.classList.toggle("is-active", b === btn));
            applyFilters();
        });
    });

    // Mở/đóng chi tiết tiêu chí nghiệm thu
    document.addEventListener("click", (e) => {
        const titleBtn = e.target.closest("[data-toggle-details]");
        if (!titleBtn) return;

        const itemId = titleBtn.getAttribute("data-toggle-details");
        const detailsEl = document.getElementById(`details-${itemId}`);
        if (!detailsEl) return;

        const isExpanded = titleBtn.getAttribute("aria-expanded") === "true";
        titleBtn.setAttribute("aria-expanded", isExpanded ? "false" : "true");
        detailsEl.hidden = isExpanded;
    });

    // Toast lỗi
    function showErrorToast(message, retryFn) {
        pendingRetryAction = retryFn;
        if (toastMessage) {
            toastMessage.textContent = message;
        }
        if (toast) {
            toast.hidden = false;
        }
    }

    function hideErrorToast() {
        if (toast) {
            toast.hidden = true;
        }
        pendingRetryAction = null;
    }

    toastCloseBtn?.addEventListener("click", hideErrorToast);
    toastRetryBtn?.addEventListener("click", () => {
        const action = pendingRetryAction;
        hideErrorToast();
        if (typeof action === "function") {
            action();
        }
    });

    // Cập nhật bộ đếm & tiến độ sau khi máy chủ xác nhận lưu
    function updateConfirmedProgress(payload) {
        if (payload.overall) {
            const { completed, total, percent } = payload.overall;
            const setText = (id, val) => {
                const el = document.getElementById(id);
                if (el) el.textContent = String(val);
            };
            setText("overall-completed", completed);
            setText("overall-total", total);
            setText("overall-percent", percent);
            setText("summary-completed", completed);
            setText("summary-total", total);
            setText("summary-percent", percent);

            const fill = document.getElementById("overall-progress-fill");
            if (fill) fill.style.width = `${percent}%`;

            const bar = document.getElementById("overall-progressbar");
            if (bar) bar.setAttribute("aria-valuenow", String(percent));
        }

        if (Array.isArray(payload.groups)) {
            payload.groups.forEach((g) => {
                const text = `${g.completed}/${g.total}`;
                document.querySelectorAll(`[data-group-counter="${g.groupId}"]`).forEach((el) => {
                    el.textContent = text;
                });
                document.querySelectorAll(`[data-summary-count="${g.groupId}"]`).forEach((el) => {
                    el.textContent = text;
                });
                const pct = g.total === 0 ? 0 : Math.round((g.completed * 100) / g.total);
                document.querySelectorAll(`[data-summary-bar="${g.groupId}"]`).forEach((el) => {
                    el.style.width = `${pct}%`;
                });
            });
        }
    }

    function formatLocalDateTime(isoString) {
        if (!isoString) return "";
        const d = new Date(isoString);
        if (Number.isNaN(d.getTime())) return "";
        const pad = (n) => String(n).padStart(2, "0");
        return `${pad(d.getDate())}/${pad(d.getMonth() + 1)}/${d.getFullYear()} ${pad(d.getHours())}:${pad(d.getMinutes())}`;
    }

    // Lưu trạng thái checkbox vào SQL Server
    async function toggleItemStatus(checkboxBtn, targetCompleted) {
        const itemId = checkboxBtn.dataset.itemId;
        const card = checkboxBtn.closest(".task-card");
        if (!itemId || !card || checkboxBtn.disabled) return;

        const savedCompleted = card.dataset.completed === "true";

        // Khóa checkbox trong lúc chờ máy chủ phản hồi
        checkboxBtn.disabled = true;
        card.classList.add("is-saving");

        try {
            const response = await fetch(`/api/items/${itemId}/status`, {
                method: "POST",
                headers: {
                    "Content-Type": "application/json",
                    "Accept": "application/json"
                },
                body: JSON.stringify({ isCompleted: targetCompleted })
            });

            if (!response.ok) {
                let errDetail = `Máy chủ trả về lỗi (${response.status}).`;
                try {
                    const errJson = await response.json();
                    if (errJson?.detail || errJson?.title || errJson?.message) {
                        errDetail = errJson.detail || errJson.message || errJson.title;
                    }
                } catch {
                    // Ignore JSON parse error
                }
                throw new Error(errDetail);
            }

            const data = await response.json();
            const confirmed = Boolean(data.isCompleted);

            card.dataset.completed = confirmed ? "true" : "false";
            card.classList.toggle("is-completed", confirmed);
            checkboxBtn.setAttribute("aria-checked", confirmed ? "true" : "false");

            const badge = card.querySelector(`[data-status-badge="${itemId}"]`);
            if (badge) {
                badge.textContent = confirmed ? "Đã xong" : "Cần làm";
            }

            const updatedEl = card.querySelector(`[data-updated-at="${itemId}"]`);
            if (updatedEl && data.updatedAt) {
                updatedEl.textContent = `Cập nhật: ${formatLocalDateTime(data.updatedAt)}`;
            }

            updateConfirmedProgress(data);
            applyFilters();
            hideErrorToast();
        } catch (err) {
            // Trả checkbox về đúng trạng thái đã lưu trước đó
            card.dataset.completed = savedCompleted ? "true" : "false";
            card.classList.toggle("is-completed", savedCompleted);
            checkboxBtn.setAttribute("aria-checked", savedCompleted ? "true" : "false");

            showErrorToast(
                `${err.message || "Không thể kết nối SQL Server."} Trạng thái cũ đã được giữ nguyên.`,
                () => toggleItemStatus(checkboxBtn, targetCompleted)
            );
        } finally {
            checkboxBtn.disabled = false;
            card.classList.remove("is-saving");
        }
    }

    document.addEventListener("click", (e) => {
        const checkboxBtn = e.target.closest(".task-checkbox");
        if (!checkboxBtn) return;
        const card = checkboxBtn.closest(".task-card");
        if (!card) return;
        const currentCompleted = card.dataset.completed === "true";
        toggleItemStatus(checkboxBtn, !currentCompleted);
    });
})();
