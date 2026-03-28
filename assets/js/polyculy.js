/* ============================================================
   Polyculy — Client-Side JavaScript
   ============================================================ */

var Polyculy = (function() {

    // Lowercase all keys recursively (Lucee returns uppercase column names)
    function normalizeKeys(obj) {
        if (Array.isArray(obj)) return obj.map(normalizeKeys);
        if (obj && typeof obj === 'object') {
            var out = {};
            Object.keys(obj).forEach(function(k) { out[k.toLowerCase()] = normalizeKeys(obj[k]); });
            return out;
        }
        return obj;
    }

    function apiGet(url) {
        return $.ajax({ url: url, method: 'GET', dataType: 'json' })
            .then(function(resp) { return normalizeKeys(resp); });
    }

    function apiPost(url, data) {
        return $.ajax({ url: url, method: 'POST', data: data, dataType: 'json' })
            .then(function(resp) { return normalizeKeys(resp); });
    }

    function showAlert(message, type) {
        type = type || 'info';
        var alertHtml = '<div class="alert-inline ' + type + '" style="position:fixed;top:70px;right:20px;z-index:9999;min-width:300px;box-shadow:0 4px 12px rgba(0,0,0,0.15);">' +
            '<i class="fas fa-' + (type === 'success' ? 'check-circle' : type === 'error' ? 'exclamation-circle' : 'info-circle') + ' me-2"></i>' +
            message + '</div>';
        var $alert = $(alertHtml).appendTo('body');
        setTimeout(function() { $alert.fadeOut(300, function() { $(this).remove(); }); }, 3500);
    }

    // ---- Notifications ----
    function loadNotificationCount() {
        apiGet('/api/notifications.cfm?action=unreadCount').done(function(resp) {
            if (resp.success) {
                var count = resp.count || 0;
                var $badge = $('#notifBadge');
                if (count > 0) {
                    $badge.text(count).show();
                } else {
                    $badge.hide();
                }
            }
        });
    }

    function toggleNotifications() {
        var $panel = $('#notificationPanel');
        var $overlay = $('#notifOverlay');
        if ($panel.is(':visible')) {
            $panel.hide();
            $overlay.hide();
        } else {
            $panel.show();
            $overlay.show();
            loadNotifications();
        }
    }

    function loadNotifications() {
        apiGet('/api/notifications.cfm?action=list&limit=15').done(function(resp) {
            if (!resp.success) return;
            var html = '';
            var notifications = resp.data || [];
            if (notifications.length === 0) {
                html = '<div class="text-center text-muted py-3">No notifications</div>';
            } else {
                notifications.forEach(function(n) {
                    var iconClass = 'fas fa-bell';
                    if (n.notification_type && n.notification_type.indexOf('connection') !== -1) iconClass = 'fas fa-users';
                    if (n.notification_type && n.notification_type.indexOf('event') !== -1) iconClass = 'fas fa-calendar';
                    if (n.notification_type && n.notification_type.indexOf('proposal') !== -1) iconClass = 'fas fa-clock';

                    html += '<div class="notif-item ' + (!n.is_read ? 'unread' : '') + '" onclick="Polyculy.markNotificationRead(' + n.notification_id + ')">' +
                        '<div class="notif-icon"><i class="' + iconClass + '"></i></div>' +
                        '<div><div class="notif-text">' + (n.title || '') + '</div>' +
                        '<div class="notif-time">' + formatTimeAgo(n.created_at) + '</div></div></div>';
                });
            }
            $('#notifList').html(html);
        });
    }

    function markNotificationRead(notifId) {
        apiPost('/api/notifications.cfm?action=markRead', { notificationId: notifId }).done(function() {
            loadNotificationCount();
            loadNotifications();
        });
    }

    function markAllNotificationsRead() {
        apiPost('/api/notifications.cfm?action=markAllRead', {}).done(function() {
            loadNotificationCount();
            loadNotifications();
        });
    }

    function formatTimeAgo(dateStr) {
        if (!dateStr) return '';
        try {
            var date = new Date(dateStr.replace(/\{ts\s+'(.+)'\}/, '$1'));
            var now = new Date();
            var diff = Math.floor((now - date) / 60000);
            if (diff < 1) return 'just now';
            if (diff < 60) return diff + 'm ago';
            if (diff < 1440) return Math.floor(diff / 60) + 'h ago';
            return Math.floor(diff / 1440) + 'd ago';
        } catch (e) { return ''; }
    }

    // ---- Auth ----
    function login(email, password) {
        return apiPost('/api/auth.cfm?action=login', { email: email, password: password });
    }

    function logout() {
        apiPost('/api/auth.cfm?action=logout', {}).done(function() {
            window.location.href = '/index.cfm';
        });
    }

    function signup(email, licenceCode) {
        return apiPost('/api/auth.cfm?action=signup', { email: email, licenceCode: licenceCode });
    }

    function completeSignup(email, password, licenceCode, displayName) {
        return apiPost('/api/auth.cfm?action=completeSignup', {
            email: email, password: password, licenceCode: licenceCode, displayName: displayName
        });
    }

    // ---- Connections ----
    function loadPolycule() {
        return apiGet('/api/connections.cfm?action=list');
    }

    function loadConnectedMembers() {
        return apiGet('/api/connections.cfm?action=connected');
    }

    function sendConnectionRequest(email, displayName) {
        return apiPost('/api/connections.cfm?action=send', { email: email, displayName: displayName });
    }

    function confirmConnection(connectionId) {
        return apiPost('/api/connections.cfm?action=confirm', { connectionId: connectionId });
    }

    function revokeConnection(connectionId) {
        return apiPost('/api/connections.cfm?action=revoke', { connectionId: connectionId });
    }

    function giftLicence(email) {
        return apiPost('/api/connections.cfm?action=giftLicence', { email: email });
    }

    // ---- Calendar ----
    function loadCalendarEvents(startDate, endDate) {
        var params = 'action=events';
        if (startDate) params += '&startDate=' + startDate;
        if (endDate) params += '&endDate=' + endDate;
        return apiGet('/api/calendar.cfm?' + params);
    }

    function loadOverlayEvents(startDate, endDate) {
        var params = 'action=overlay';
        if (startDate) params += '&startDate=' + startDate;
        if (endDate) params += '&endDate=' + endDate;
        return apiGet('/api/calendar.cfm?' + params);
    }

    function setupCalendar(method) {
        return apiPost('/api/calendar.cfm?action=setup', { method: method });
    }

    // ---- Events ----
    function createPersonalEvent(formData) {
        return apiPost('/api/events.cfm?action=create', formData);
    }

    function createSharedEvent(formData) {
        return apiPost('/api/shared-events.cfm?action=create', formData);
    }

    function respondToInvitation(eventId, response) {
        return apiPost('/api/shared-events.cfm?action=respond', { eventId: eventId, response: response });
    }

    function getSharedEvent(eventId) {
        return apiGet('/api/shared-events.cfm?action=get&id=' + eventId);
    }

    // ---- Sharing Mutual Exclusivity ----
    function initSharingControls() {
        var $invisible = $('#visInvisible');
        var $fullDetails = $('#visFullDetails');
        var $busyBlock = $('#visBusyBlock');
        var $fullAudience = $('[name="fullDetailAudience"]');
        var $busyAudience = $('[name="busyBlockAudience"]');

        $invisible.on('change', function() {
            if (this.checked) {
                $fullDetails.prop('checked', false).prop('disabled', true);
                $busyBlock.prop('checked', false).prop('disabled', true);
                $('.full-detail-options, .busy-block-options').addClass('disabled-section');
            }
        });

        $fullDetails.on('change', function() {
            if (this.checked) {
                $invisible.prop('checked', false);
                $busyBlock.prop('disabled', false);
                $('.full-detail-options').removeClass('disabled-section');
            } else {
                $('.full-detail-options').addClass('disabled-section');
            }
            updateBusyBlockAvailability();
        });

        $busyBlock.on('change', function() {
            if (this.checked) {
                $invisible.prop('checked', false);
                $('.busy-block-options').removeClass('disabled-section');
            } else {
                $('.busy-block-options').addClass('disabled-section');
            }
        });

        $fullAudience.on('change', function() {
            updateBusyBlockAvailability();
        });

        // Person checkboxes - enforce mutual exclusivity
        $('.full-detail-person').on('change', function() {
            var userId = $(this).val();
            var $busyCheckbox = $('.busy-block-person[value="' + userId + '"]');
            if (this.checked) {
                $busyCheckbox.prop('checked', false).prop('disabled', true);
            } else {
                $busyCheckbox.prop('disabled', false);
            }
        });
    }

    function updateBusyBlockAvailability() {
        var fullAudience = $('[name="fullDetailAudience"]:checked').val();
        if (fullAudience === 'entire') {
            $('#visBusyBlock').prop('checked', false).prop('disabled', true);
            $('.busy-block-options').addClass('disabled-section');
        } else {
            $('#visBusyBlock').prop('disabled', false);
            // Grey out people selected in full details
            var $busyEntire = $('[name="busyBlockAudience"][value="entire"]');
            if ($('#visFullDetails').is(':checked') && fullAudience === 'specific') {
                $busyEntire.prop('disabled', true);
            } else {
                $busyEntire.prop('disabled', false);
            }
        }
    }

    // ---- Calendar Rendering ----
    var currentDate = new Date();
    var currentView = 'month';
    var currentPerspective = 'mine';
    var calendarToggleStates = {};

    function initCalendar() {
        renderCalendar();
        loadNotificationCount();

        // Load toggle states
        apiGet('/api/calendar.cfm?action=toggleState').done(function(resp) {
            if (resp.data) calendarToggleStates = resp.data;
        });
    }

    function renderCalendar() {
        if (currentView === 'month') renderMonthView();
        else if (currentView === 'week') renderWeekView();
        else renderDayView();
    }

    function renderMonthView() {
        var year = currentDate.getFullYear();
        var month = currentDate.getMonth();
        var firstDay = new Date(year, month, 1);
        var lastDay = new Date(year, month + 1, 0);
        var startDayOfWeek = firstDay.getDay();
        var daysInMonth = lastDay.getDate();
        var today = new Date();

        var monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];
        var titleText = monthNames[month] + ' ' + year;
        $('#calendarTitle').text(titleText);
        $('#calendarNavTitle').text(titleText);

        var startDate = new Date(year, month, 1 - startDayOfWeek);
        var endDate = new Date(year, month + 1, 6);

        var startStr = formatDateISO(startDate);
        var endStr = formatDateISO(endDate);

        // Load events
        var eventPromise = loadCalendarEvents(startStr, endStr);
        var overlayPromise = (currentPerspective === 'our') ? loadOverlayEvents(startStr, endStr) : $.Deferred().resolve({ success: true, data: [] });

        $.when(eventPromise, overlayPromise).done(function(evResp, ovResp) {
            var events = (evResp.data || []);
            var overlayEvents = (ovResp && ovResp.data) ? ovResp.data : [];

            var html = '<table><thead><tr>';
            var dayNames = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];
            dayNames.forEach(function(d) { html += '<th>' + d + '</th>'; });
            html += '</tr></thead><tbody>';

            var currentCellDate = new Date(startDate);
            for (var week = 0; week < 6; week++) {
                html += '<tr>';
                for (var day = 0; day < 7; day++) {
                    var isOtherMonth = currentCellDate.getMonth() !== month;
                    var isToday = currentCellDate.toDateString() === today.toDateString();
                    var cellClass = '';
                    if (isOtherMonth) cellClass += ' other-month';
                    if (isToday) cellClass += ' today';

                    html += '<td class="' + cellClass + '">';
                    html += '<div class="day-number' + (isToday ? ' today' : '') + '">' + currentCellDate.getDate() + '</div>';

                    // Render events for this day
                    var cellDateStr = formatDateISO(currentCellDate);
                    var dayEvents = events.filter(function(e) {
                        return e.start && e.start.substring(0, 10) === cellDateStr;
                    });
                    var dayOverlay = overlayEvents.filter(function(e) {
                        return e.start && e.start.substring(0, 10) === cellDateStr;
                    });

                    dayEvents.forEach(function(ev) {
                        var evClass = 'cal-event ';
                        if (ev.type === 'personal') evClass += 'personal';
                        else if (ev.state === 'active') evClass += 'shared-active';
                        else evClass += 'shared-tentative';

                        var timeStr = formatTime(ev.start);
                        var endTimeStr = ev.end ? ' - ' + formatTime(ev.end) : '';

                        html += '<div class="' + evClass + '" onclick="Polyculy.showEventDetail(\'' + ev.type + '\',' + ev.id + ')" title="' + escapeHtml(ev.title) + '">';
                        html += '<span>' + escapeHtml(ev.title) + '</span>';
                        html += '</div>';
                    });

                    if (currentPerspective === 'our') {
                        dayOverlay.forEach(function(ev) {
                            html += '<div class="cal-event overlay" style="background:' + (ev.calendarcolor || '#7C3AED') + ';" title="' + escapeHtml(ev.title || 'Busy') + '">';
                            html += '<span>' + escapeHtml(ev.title || 'Busy') + '</span>';
                            html += '</div>';
                        });
                    }

                    html += '</td>';
                    currentCellDate.setDate(currentCellDate.getDate() + 1);
                }
                html += '</tr>';
                if (currentCellDate.getMonth() !== month && currentCellDate.getDate() > 7) break;
            }

            html += '</tbody></table>';
            $('#calendarGrid').html(html);
        });
    }

    function renderWeekView() {
        var startOfWeek = new Date(currentDate);
        startOfWeek.setDate(currentDate.getDate() - currentDate.getDay());
        var endOfWeek = new Date(startOfWeek);
        endOfWeek.setDate(startOfWeek.getDate() + 6);

        var monthNames = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
        var weekTitle = 'Week of ' + monthNames[startOfWeek.getMonth()] + ' ' + startOfWeek.getDate() + ', ' + startOfWeek.getFullYear();
        $('#calendarTitle').text(weekTitle);
        $('#calendarNavTitle').text(weekTitle);

        var startStr = formatDateISO(startOfWeek);
        var endStr = formatDateISO(endOfWeek);

        var eventPromise = loadCalendarEvents(startStr, endStr);
        var overlayPromise = (currentPerspective === 'our') ? loadOverlayEvents(startStr, endStr) : $.Deferred().resolve({ success: true, data: [] });

        $.when(eventPromise, overlayPromise).done(function(evResp, ovResp) {
            var events = evResp.data || [];
            var overlayEvents = (ovResp && ovResp.data) ? ovResp.data : [];
            var today = new Date();
            var dayNames = ['Sun','Mon','Tue','Wed','Thu','Fri','Sat'];

            var html = '<table><thead><tr><th style="width:60px;">Time</th>';
            for (var d = 0; d < 7; d++) {
                var dayDate = new Date(startOfWeek);
                dayDate.setDate(startOfWeek.getDate() + d);
                var isToday = dayDate.toDateString() === today.toDateString();
                html += '<th' + (isToday ? ' class="today"' : '') + '>' + dayNames[d] + ' ' + dayDate.getDate() + '</th>';
            }
            html += '</tr></thead><tbody>';

            for (var hour = 7; hour <= 22; hour++) {
                html += '<tr>';
                var ampm = hour >= 12 ? 'PM' : 'AM';
                var displayHour = hour > 12 ? hour - 12 : (hour === 0 ? 12 : hour);
                html += '<td><span class="time-label">' + displayHour + ' ' + ampm + '</span></td>';

                for (var d = 0; d < 7; d++) {
                    var dayDate = new Date(startOfWeek);
                    dayDate.setDate(startOfWeek.getDate() + d);
                    var cellDateStr = formatDateISO(dayDate);

                    html += '<td style="position:relative;">';

                    // Find events at this hour
                    var hourEvents = events.filter(function(e) {
                        if (!e.start || e.start.substring(0, 10) !== cellDateStr) return false;
                        var eHour = parseInt(e.start.substring(11, 13));
                        return eHour === hour;
                    });

                    hourEvents.forEach(function(ev) {
                        var evClass = ev.type === 'personal' ? 'personal' : (ev.state === 'active' ? 'shared-active' : 'shared-tentative');
                        var startTime = formatTime(ev.start);
                        var endTime = ev.end ? formatTime(ev.end) : '';
                        html += '<div class="cal-event ' + evClass + '" onclick="Polyculy.showEventDetail(\'' + ev.type + '\',' + ev.id + ')">';
                        html += startTime + (endTime ? ' - ' + endTime : '');
                        html += '</div>';
                    });

                    // Overlay events
                    if (currentPerspective === 'our') {
                        var hourOverlay = overlayEvents.filter(function(e) {
                            if (!e.start || e.start.substring(0, 10) !== cellDateStr) return false;
                            var eHour = parseInt(e.start.substring(11, 13));
                            return eHour === hour;
                        });
                        hourOverlay.forEach(function(ev) {
                            html += '<div class="cal-event overlay" style="background:' + (ev.calendarcolor || '#7C3AED') + ';">';
                            html += formatTime(ev.start) + (ev.end ? ' - ' + formatTime(ev.end) : '');
                            html += '</div>';
                        });
                    }

                    // Current time line
                    var isToday = dayDate.toDateString() === today.toDateString();
                    if (isToday && today.getHours() === hour) {
                        var minuteOffset = (today.getMinutes() / 60) * 100;
                        html += '<div class="current-time-line" style="top:' + minuteOffset + '%;"></div>';
                    }

                    html += '</td>';
                }
                html += '</tr>';
            }

            html += '</tbody></table>';
            $('#calendarGrid').html(html);
        });
    }

    function renderDayView() {
        var monthNames = ['January','February','March','April','May','June','July','August','September','October','November','December'];
        var dayNames = ['Sunday','Monday','Tuesday','Wednesday','Thursday','Friday','Saturday'];
        var dayTitle = dayNames[currentDate.getDay()] + ', ' + monthNames[currentDate.getMonth()] + ' ' + currentDate.getDate() + ', ' + currentDate.getFullYear();
        $('#calendarTitle').text(dayTitle);
        $('#calendarNavTitle').text(dayTitle);

        var dateStr = formatDateISO(currentDate);
        var eventPromise = loadCalendarEvents(dateStr, dateStr);

        eventPromise.done(function(resp) {
            var events = resp.data || [];
            var today = new Date();
            var html = '<table><thead><tr><th style="width:80px;">Time</th><th>Events</th></tr></thead><tbody>';

            for (var hour = 7; hour <= 22; hour++) {
                var ampm = hour >= 12 ? 'PM' : 'AM';
                var displayHour = hour > 12 ? hour - 12 : (hour === 0 ? 12 : hour);
                html += '<tr><td><span class="time-label">' + displayHour + ':00 ' + ampm + '</span></td><td style="position:relative;">';

                var hourEvents = events.filter(function(e) {
                    if (!e.start || e.start.substring(0, 10) !== dateStr) return false;
                    var eHour = parseInt(e.start.substring(11, 13));
                    return eHour === hour;
                });

                hourEvents.forEach(function(ev) {
                    var evClass = ev.type === 'personal' ? 'personal' : (ev.state === 'active' ? 'shared-active' : 'shared-tentative');
                    html += '<div class="cal-event ' + evClass + '" onclick="Polyculy.showEventDetail(\'' + ev.type + '\',' + ev.id + ')">';
                    html += escapeHtml(ev.title) + ' (' + formatTime(ev.start) + (ev.end ? ' - ' + formatTime(ev.end) : '') + ')';
                    html += '</div>';
                });

                if (currentDate.toDateString() === today.toDateString() && today.getHours() === hour) {
                    var minuteOffset = (today.getMinutes() / 60) * 100;
                    html += '<div class="current-time-line" style="top:' + minuteOffset + '%;"></div>';
                }

                html += '</td></tr>';
            }

            html += '</tbody></table>';
            $('#calendarGrid').html(html);
        });
    }

    function navigateCalendar(direction) {
        if (currentView === 'month') {
            currentDate.setMonth(currentDate.getMonth() + direction);
        } else if (currentView === 'week') {
            currentDate.setDate(currentDate.getDate() + (7 * direction));
        } else {
            currentDate.setDate(currentDate.getDate() + direction);
        }
        renderCalendar();
    }

    function setView(view) {
        currentView = view;
        $('.view-toggle-btn').removeClass('active');
        $('.view-toggle-btn[data-view="' + view + '"]').addClass('active');
        renderCalendar();
    }

    function setPerspective(perspective) {
        currentPerspective = perspective;
        $('.view-toggle-btn[data-perspective]').removeClass('active');
        $('.view-toggle-btn[data-perspective="' + perspective + '"]').addClass('active');
        renderCalendar();
        renderToggleBar();
    }

    function renderToggleBar() {
        if (currentPerspective !== 'our') {
            $('#toggleBar').hide();
            return;
        }
        $('#toggleBar').show();
        loadConnectedMembers().done(function(resp) {
            if (!resp.success) return;
            var html = '<div class="toggle-pill active" onclick="Polyculy.toggleMember(0)" style="color:var(--purple-600);">' +
                '<span class="pill-dot" style="background:var(--purple-600);"></span>' +
                '<span>My Calendar</span><span class="pill-switch"></span></div>';

            (resp.data || []).forEach(function(m) {
                var isOn = calendarToggleStates[m.userid] !== false;
                html += '<div class="toggle-pill' + (isOn ? ' active' : '') + '" onclick="Polyculy.toggleMember(' + m.userid + ')" style="color:' + (m.calendarcolor || '#7C3AED') + ';">' +
                    '<span class="pill-dot" style="background:' + (m.calendarcolor || '#7C3AED') + ';"></span>' +
                    '<span>' + escapeHtml(m.displayname) + '</span><span class="pill-switch"></span></div>';
            });

            $('#toggleBar').html(html);
        });
    }

    function toggleMember(userId) {
        if (userId === 0) return; // My Calendar always on in Our mode
        calendarToggleStates[userId] = !calendarToggleStates[userId];
        apiPost('/api/calendar.cfm?action=toggleState', { targetUserId: userId, isVisible: calendarToggleStates[userId] });
        renderToggleBar();
        renderCalendar();
    }

    function showEventDetail(type, eventId) {
        if (type === 'personal') {
            apiGet('/api/events.cfm?action=get&id=' + eventId).done(function(resp) {
                if (!resp.success) return;
                var ev = resp.data;
                var html = '<div class="invitation-card">' +
                    '<div class="inv-title">' + escapeHtml(ev.title) + '</div>' +
                    '<div class="inv-meta"><i class="far fa-clock me-1"></i>' + formatDateTime(ev.start_time) + (ev.end_time ? ' - ' + formatTime(ev.end_time) : '') + '</div>';
                if (ev.address) html += '<div class="inv-meta"><i class="fas fa-map-marker-alt me-1"></i>' + escapeHtml(ev.address) + '</div>';
                if (ev.event_details) html += '<div class="inv-meta">' + escapeHtml(ev.event_details) + '</div>';
                html += '</div>';
                showModal('Event Details', html);
            });
        } else {
            apiGet('/api/shared-events.cfm?action=get&id=' + eventId).done(function(resp) {
                if (!resp.success) return;
                var ev = resp.data;
                var html = '<div class="invitation-card">' +
                    '<div class="inv-header"><div class="member-avatar" style="width:32px;height:32px;font-size:0.75rem;">' + escapeHtml(ev.organizer_name ? ev.organizer_name.charAt(0) : 'O') + '</div>' +
                    '<div><div class="inv-title">' + escapeHtml(ev.title) + '</div>' +
                    '<div class="text-muted-sm">Organized by ' + escapeHtml(ev.organizer_name || '') + '</div></div></div>' +
                    '<div class="inv-meta"><i class="far fa-clock me-1"></i>' + formatDateTime(ev.start_time) + (ev.end_time ? ' - ' + formatTime(ev.end_time) : '') + '</div>';
                if (ev.address) html += '<div class="inv-meta"><i class="fas fa-map-marker-alt me-1"></i>' + escapeHtml(ev.address) + '</div>';
                if (ev.event_details) html += '<div class="inv-meta">' + escapeHtml(ev.event_details) + '</div>';

                // State badge
                html += '<div class="mb-2"><span class="proposal-status ' + ev.global_state + '">' + ev.global_state + '</span></div>';

                // Participants
                if (ev.participants && ev.participants.length > 0) {
                    html += '<div class="mt-2"><strong class="text-purple" style="font-size:0.85rem;">Participants</strong>';
                    ev.participants.forEach(function(p) {
                        html += '<div class="invite-row"><span class="invite-color" style="background:' + (p.calendar_color || '#7C3AED') + ';"></span>' +
                            '<span class="invite-name">' + escapeHtml(p.display_name) + '</span>' +
                            '<span class="proposal-status ' + p.response_status + '">' + p.response_status + '</span></div>';
                    });
                    html += '</div>';
                }

                html += '</div>';
                showModal('Shared Event', html);
            });
        }
    }

    function showModal(title, bodyHtml, footerHtml) {
        var $existing = $('#polyculy-dynamic-modal');
        if ($existing.length) $existing.remove();

        var modalHtml = '<div class="modal fade modal-polyculy" id="polyculy-dynamic-modal" tabindex="-1">' +
            '<div class="modal-dialog modal-dialog-centered"><div class="modal-content">' +
            '<div class="modal-header"><h5 class="modal-title"><svg width="20" height="20" viewBox="0 0 40 40"><path d="M15 6C10 6 6 10 6 15C6 25 23 34 23 34C23 34 40 25 40 15C40 10 36 6 31 6C27.5 6 24.5 8 23 11C21.5 8 18.5 6 15 6Z" fill="url(#hg)"/><defs><linearGradient id="hg" x1="6" y1="6" x2="40" y2="34"><stop stop-color="#A855F7"/><stop offset="1" stop-color="#7C3AED"/></linearGradient></defs></svg> ' + title + '</h5>' +
            '<button type="button" class="btn-close" data-bs-dismiss="modal"></button></div>' +
            '<div class="modal-body">' + bodyHtml + '</div>';
        if (footerHtml) {
            modalHtml += '<div class="modal-footer">' + footerHtml + '</div>';
        }
        modalHtml += '</div></div></div>';

        $('body').append(modalHtml);
        var modal = new bootstrap.Modal(document.getElementById('polyculy-dynamic-modal'));
        modal.show();
    }

    // ---- Helpers ----
    function formatDateISO(date) {
        var y = date.getFullYear();
        var m = String(date.getMonth() + 1).padStart(2, '0');
        var d = String(date.getDate()).padStart(2, '0');
        return y + '-' + m + '-' + d;
    }

    function formatTime(dateStr) {
        if (!dateStr) return '';
        try {
            var str = dateStr.replace(/\{ts\s+'(.+)'\}/, '$1');
            var d = new Date(str);
            if (isNaN(d)) return dateStr.substring(11, 16);
            var h = d.getHours();
            var m = String(d.getMinutes()).padStart(2, '0');
            var ampm = h >= 12 ? 'PM' : 'AM';
            h = h > 12 ? h - 12 : (h === 0 ? 12 : h);
            return h + ':' + m + ' ' + ampm;
        } catch (e) { return ''; }
    }

    function formatDateTime(dateStr) {
        if (!dateStr) return '';
        try {
            var str = dateStr.replace(/\{ts\s+'(.+)'\}/, '$1');
            var d = new Date(str);
            if (isNaN(d)) return dateStr;
            var months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
            return months[d.getMonth()] + ' ' + d.getDate() + ', ' + d.getFullYear() + ' ' + formatTime(dateStr);
        } catch (e) { return dateStr; }
    }

    function escapeHtml(str) {
        if (!str) return '';
        return String(str).replace(/&/g,'&amp;').replace(/</g,'&lt;').replace(/>/g,'&gt;').replace(/"/g,'&quot;');
    }

    // ---- Public API ----
    return {
        apiGet: apiGet,
        apiPost: apiPost,
        showAlert: showAlert,
        normalizeKeys: normalizeKeys,
        // Auth
        login: login,
        logout: logout,
        signup: signup,
        completeSignup: completeSignup,
        // Notifications
        loadNotificationCount: loadNotificationCount,
        toggleNotifications: toggleNotifications,
        markNotificationRead: markNotificationRead,
        markAllNotificationsRead: markAllNotificationsRead,
        // Connections
        loadPolycule: loadPolycule,
        loadConnectedMembers: loadConnectedMembers,
        sendConnectionRequest: sendConnectionRequest,
        confirmConnection: confirmConnection,
        revokeConnection: revokeConnection,
        giftLicence: giftLicence,
        // Calendar
        loadCalendarEvents: loadCalendarEvents,
        loadOverlayEvents: loadOverlayEvents,
        setupCalendar: setupCalendar,
        initCalendar: initCalendar,
        renderCalendar: renderCalendar,
        navigateCalendar: navigateCalendar,
        setView: setView,
        setPerspective: setPerspective,
        renderToggleBar: renderToggleBar,
        toggleMember: toggleMember,
        showEventDetail: showEventDetail,
        // Events
        createPersonalEvent: createPersonalEvent,
        createSharedEvent: createSharedEvent,
        respondToInvitation: respondToInvitation,
        // Sharing
        initSharingControls: initSharingControls,
        // UI
        showModal: showModal,
        formatDateISO: formatDateISO,
        formatTime: formatTime,
        formatDateTime: formatDateTime,
        escapeHtml: escapeHtml
    };

})();

// Init on page load
$(document).ready(function() {
    Polyculy.loadNotificationCount();
    // Refresh notification count every 30 seconds
    setInterval(Polyculy.loadNotificationCount, 30000);
});
