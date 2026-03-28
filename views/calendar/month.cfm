<cf_main pageTitle="My Calendar" showNav="true">
<cfoutput>
<div class="page-container calendar-page">
    <div class="calendar-header">
        <div class="calendar-header-left">
            <h2 class="page-title" id="calendarTitle" data-testid="calendar-title">My Calendar</h2>
        </div>
        <div class="calendar-header-actions">
            <button class="btn btn-primary-purple btn-sm" onclick="openPersonalEventModal()">
                <i class="fas fa-plus me-1"></i>Personal Event
            </button>
            <button class="btn btn-outline-purple btn-sm" onclick="window.location.href='/views/events/shared.cfm'">
                <i class="fas fa-share me-1"></i>Shared Event Invitation
            </button>
        </div>
    </div>

    <div class="calendar-controls">
        <div class="view-toggle-group">
            <button class="view-toggle-btn" data-view="day" data-testid="view-day" onclick="Polyculy.setView('day')">Day</button>
            <button class="view-toggle-btn" data-view="week" data-testid="view-week" onclick="Polyculy.setView('week')">Week</button>
            <button class="view-toggle-btn active" data-view="month" data-testid="view-month" onclick="Polyculy.setView('month')">Month</button>
        </div>
        <div class="calendar-nav">
            <button class="btn-nav" onclick="Polyculy.navigateCalendar(-1)"><i class="fas fa-chevron-left"></i></button>
            <span class="calendar-nav-title" id="calendarNavTitle" data-testid="calendar-nav-title">Loading...</span>
            <button class="btn-nav" onclick="Polyculy.navigateCalendar(1)"><i class="fas fa-chevron-right"></i></button>
        </div>
        <div class="view-toggle-group">
            <button class="view-toggle-btn active" data-perspective="mine" data-testid="perspective-mine" onclick="Polyculy.setPerspective('mine')">Mine</button>
            <button class="view-toggle-btn" data-perspective="our" data-testid="perspective-our" onclick="Polyculy.setPerspective('our')">Our</button>
        </div>
    </div>

    <div class="calendar-grid" id="calendarGrid" data-testid="calendar-grid">
        <div class="text-center text-muted py-5"><i class="fas fa-spinner fa-spin fa-2x"></i></div>
    </div>

    <!--- Toggle Bar for Our view --->
    <div class="toggle-bar" id="toggleBar" data-testid="toggle-bar" style="display:none;"></div>
</div>

<!--- Personal Event Modal --->
<div class="modal fade modal-polyculy" id="personalEventModal" data-testid="personal-event-modal" tabindex="-1">
    <div class="modal-dialog modal-lg modal-dialog-centered">
        <div class="modal-content">
            <div class="modal-header">
                <h5 class="modal-title">
                    <svg width="20" height="20" viewBox="0 0 40 40"><path d="M15 6C10 6 6 10 6 15C6 25 23 34 23 34C23 34 40 25 40 15C40 10 36 6 31 6C27.5 6 24.5 8 23 11C21.5 8 18.5 6 15 6Z" fill="url(##hmg)"/><defs><linearGradient id="hmg" x1="6" y1="6" x2="40" y2="34"><stop stop-color="##A855F7"/><stop offset="1" stop-color="##7C3AED"/></linearGradient></defs></svg>
                    Add Personal Event
                </h5>
                <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
            </div>
            <div class="modal-body">
                <!--- Accordion: Event Details --->
                <div class="accordion-section active" id="eventDetailsSection">
                    <div class="accordion-header" onclick="toggleAccordion('eventDetailsSection')">
                        <span><i class="fas fa-chevron-down me-2"></i>Event Details</span>
                    </div>
                    <div class="accordion-body">
                        <div class="mb-3">
                            <label class="form-label-poly">Title <span class="text-danger">*</span></label>
                            <input type="text" class="form-control" id="peTitle" data-testid="pe-title" placeholder="e.g., Doctor's appointment" required>
                        </div>
                        <div class="row g-2 mb-3">
                            <div class="col-md-4">
                                <label class="form-label-poly">Start Date <span class="text-danger">*</span></label>
                                <input type="date" class="form-control" id="peStartDate" data-testid="pe-start-date" required>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label-poly">Hour</label>
                                <select class="form-select" id="peStartHour">
                                    <cfloop from="1" to="12" index="h"><option value="#h#"<cfif h eq 8> selected</cfif>>#h#</option></cfloop>
                                </select>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label-poly">Min</label>
                                <select class="form-select" id="peStartMinute">
                                    <option value="00">00</option><option value="15">15</option><option value="30">30</option><option value="45">45</option>
                                </select>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label-poly">AM/PM</label>
                                <select class="form-select" id="peStartAmPm"><option value="AM">AM</option><option value="PM">PM</option></select>
                            </div>
                            <div class="col-md-2 d-flex align-items-end">
                                <div class="form-check">
                                    <input class="form-check-input" type="checkbox" id="peAllDay" onchange="toggleAllDay()">
                                    <label class="form-check-label" for="peAllDay">All Day</label>
                                </div>
                            </div>
                        </div>
                        <div class="row g-2 mb-3" id="endTimeRow">
                            <div class="col-md-4">
                                <label class="form-label-poly">End Date</label>
                                <input type="date" class="form-control" id="peEndDate">
                            </div>
                            <div class="col-md-2">
                                <label class="form-label-poly">Hour</label>
                                <select class="form-select" id="peEndHour">
                                    <cfloop from="1" to="12" index="h"><option value="#h#"<cfif h eq 9> selected</cfif>>#h#</option></cfloop>
                                </select>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label-poly">Min</label>
                                <select class="form-select" id="peEndMinute">
                                    <option value="00">00</option><option value="15">15</option><option value="30">30</option><option value="45">45</option>
                                </select>
                            </div>
                            <div class="col-md-2">
                                <label class="form-label-poly">AM/PM</label>
                                <select class="form-select" id="peEndAmPm"><option value="AM">AM</option><option value="PM">PM</option></select>
                            </div>
                        </div>
                        <div class="mb-3">
                            <label class="form-label-poly">Event Details</label>
                            <textarea class="form-control" id="peDetails" data-testid="pe-details" rows="2" placeholder="Optional notes..."></textarea>
                        </div>
                        <div class="row g-2 mb-3">
                            <div class="col-md-6">
                                <label class="form-label-poly">Address</label>
                                <input type="text" class="form-control" id="peAddress" data-testid="pe-address" placeholder="Location">
                            </div>
                            <div class="col-md-6">
                                <label class="form-label-poly">Reminder</label>
                                <select class="form-select" id="peReminder">
                                    <option value="">None</option><option value="5">5 minutes</option><option value="15" selected>15 minutes</option>
                                    <option value="30">30 minutes</option><option value="60">1 hour</option><option value="1440">1 day</option>
                                </select>
                            </div>
                        </div>
                    </div>
                </div>

                <!--- Accordion: Sharing --->
                <div class="accordion-section" id="sharingSection">
                    <div class="accordion-header" onclick="toggleAccordion('sharingSection')">
                        <span><i class="fas fa-chevron-right me-2"></i>Sharing <span class="text-danger">*</span></span>
                        <span class="accordion-subtitle">Choose who can see this event</span>
                    </div>
                    <div class="accordion-body" style="display:none;">
                        <div class="sharing-options">
                            <div class="sharing-option">
                                <div class="form-check">
                                    <input class="form-check-input" type="radio" name="visibilityTier" id="visInvisible" value="invisible" checked>
                                    <label class="form-check-label" for="visInvisible"><strong>Invisible to everyone but me</strong></label>
                                </div>
                            </div>

                            <div class="sharing-option">
                                <div class="form-check">
                                    <input class="form-check-input" type="radio" name="visibilityTier" id="visFullDetails" value="full_details">
                                    <label class="form-check-label" for="visFullDetails"><strong>Share full event details with:</strong></label>
                                </div>
                                <div class="full-detail-options disabled-section" style="margin-left:28px;">
                                    <div class="form-check">
                                        <input class="form-check-input" type="radio" name="fullDetailAudience" value="entire" disabled>
                                        <label class="form-check-label">Entire polycule</label>
                                    </div>
                                    <div class="form-check">
                                        <input class="form-check-input" type="radio" name="fullDetailAudience" value="specific" disabled checked>
                                        <label class="form-check-label">Specific people</label>
                                    </div>
                                    <div class="specific-people-list full-detail-people" id="fullDetailPeople"></div>
                                </div>
                            </div>

                            <div class="sharing-option">
                                <div class="form-check">
                                    <input class="form-check-input" type="radio" name="visibilityTier" id="visBusyBlock" value="busy_block">
                                    <label class="form-check-label" for="visBusyBlock"><strong>Share as busy block only with:</strong></label>
                                </div>
                                <div class="busy-block-options disabled-section" style="margin-left:28px;">
                                    <div class="form-check">
                                        <input class="form-check-input" type="radio" name="busyBlockAudience" value="entire" disabled>
                                        <label class="form-check-label">Entire polycule</label>
                                    </div>
                                    <div class="form-check">
                                        <input class="form-check-input" type="radio" name="busyBlockAudience" value="specific" disabled checked>
                                        <label class="form-check-label">Specific people</label>
                                    </div>
                                    <div class="specific-people-list busy-block-people" id="busyBlockPeople"></div>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </div>
            <div class="modal-footer">
                <button type="button" class="btn btn-outline-secondary" data-bs-dismiss="modal">Cancel</button>
                <button type="button" class="btn btn-primary-purple" onclick="createPersonalEvent()">Create Event</button>
            </div>
        </div>
    </div>
</div>

<script>
$(document).ready(function() {
    Polyculy.initCalendar();
    loadSharingPeople();
    initVisibilityControls();
    // Set today's date as default
    var today = Polyculy.formatDateISO(new Date());
    $('##peStartDate').val(today);
    $('##peEndDate').val(today);
});

function openPersonalEventModal() {
    var modal = new bootstrap.Modal(document.getElementById('personalEventModal'));
    modal.show();
}

function toggleAccordion(sectionId) {
    var $section = $('##' + sectionId);
    var $body = $section.find('.accordion-body');
    var $icon = $section.find('.accordion-header .fas');
    if ($section.hasClass('active')) {
        $section.removeClass('active');
        $body.slideUp(200);
        $icon.removeClass('fa-chevron-down').addClass('fa-chevron-right');
    } else {
        $section.addClass('active');
        $body.slideDown(200);
        $icon.removeClass('fa-chevron-right').addClass('fa-chevron-down');
    }
}

function toggleAllDay() {
    if ($('##peAllDay').is(':checked')) {
        $('##endTimeRow').hide();
    } else {
        $('##endTimeRow').show();
    }
}

function loadSharingPeople() {
    Polyculy.loadConnectedMembers().done(function(resp) {
        if (!resp.success) return;
        var fullHtml = '';
        var busyHtml = '';
        (resp.data || []).forEach(function(m) {
            fullHtml += '<div class="form-check"><input class="form-check-input full-detail-person" type="checkbox" value="' + m.userid + '" disabled>' +
                '<label class="form-check-label">' + Polyculy.escapeHtml(m.displayname) + '</label></div>';
            busyHtml += '<div class="form-check"><input class="form-check-input busy-block-person" type="checkbox" value="' + m.userid + '" disabled>' +
                '<label class="form-check-label">' + Polyculy.escapeHtml(m.displayname) + '</label></div>';
        });
        $('##fullDetailPeople').html(fullHtml);
        $('##busyBlockPeople').html(busyHtml);
    });
}

function initVisibilityControls() {
    $('input[name="visibilityTier"]').on('change', function() {
        var val = $(this).val();
        if (val === 'invisible') {
            $('.full-detail-options, .busy-block-options').addClass('disabled-section');
            $('input[name="fullDetailAudience"], input[name="busyBlockAudience"], .full-detail-person, .busy-block-person')
                .prop('disabled', true).prop('checked', false);
        } else if (val === 'full_details') {
            $('.full-detail-options').removeClass('disabled-section');
            $('input[name="fullDetailAudience"], .full-detail-person').prop('disabled', false);
            // Busy block may still be enabled
        } else if (val === 'busy_block') {
            $('.busy-block-options').removeClass('disabled-section');
            $('input[name="busyBlockAudience"], .busy-block-person').prop('disabled', false);
        }
    });

    // Full detail audience change - enforce mutual exclusivity
    $(document).on('change', 'input[name="fullDetailAudience"]', function() {
        if ($(this).val() === 'entire') {
            // Disable busy block entirely
            $('##visBusyBlock').prop('disabled', true);
            $('.busy-block-options').addClass('disabled-section');
        } else {
            $('##visBusyBlock').prop('disabled', false);
            // Grey out in busy the people selected in full
            updateBusyExclusions();
        }
    });

    $(document).on('change', '.full-detail-person', function() {
        updateBusyExclusions();
    });
}

function updateBusyExclusions() {
    $('.busy-block-person').prop('disabled', false);
    $('.full-detail-person:checked').each(function() {
        var uid = $(this).val();
        $('.busy-block-person[value="' + uid + '"]').prop('checked', false).prop('disabled', true);
    });
    if ($('.full-detail-person:checked').length > 0) {
        $('input[name="busyBlockAudience"][value="entire"]').prop('disabled', true);
    } else {
        $('input[name="busyBlockAudience"][value="entire"]').prop('disabled', false);
    }
}

function createPersonalEvent() {
    var title = $('##peTitle').val().trim();
    if (!title) { Polyculy.showAlert('Title is required.', 'error'); return; }

    var visibilityTier = $('input[name="visibilityTier"]:checked').val();
    var fullDetailUsers = [];
    var busyBlockUsers = [];

    if (visibilityTier === 'full_details') {
        var audience = $('input[name="fullDetailAudience"]:checked').val();
        if (audience === 'specific') {
            $('.full-detail-person:checked').each(function() { fullDetailUsers.push($(this).val()); });
        }
    }
    if (visibilityTier === 'busy_block' || ($('input[name="visibilityTier"]:checked').val() !== 'invisible' && $('##visBusyBlock').is(':checked'))) {
        var busyAudience = $('input[name="busyBlockAudience"]:checked').val();
        if (busyAudience === 'specific') {
            $('.busy-block-person:checked').each(function() { busyBlockUsers.push($(this).val()); });
        }
    }

    var formData = {
        title: title,
        startDate: $('##peStartDate').val(),
        startHour: $('##peStartHour').val(),
        startMinute: $('##peStartMinute').val(),
        startAmPm: $('##peStartAmPm').val(),
        endDate: $('##peEndDate').val() || $('##peStartDate').val(),
        endHour: $('##peEndHour').val(),
        endMinute: $('##peEndMinute').val(),
        endAmPm: $('##peEndAmPm').val(),
        allDay: $('##peAllDay').is(':checked') ? 'on' : '',
        eventDetails: $('##peDetails').val(),
        address: $('##peAddress').val(),
        reminderMinutes: $('##peReminder').val(),
        visibilityTier: visibilityTier,
        fullDetailUsers: fullDetailUsers.join(','),
        busyBlockUsers: busyBlockUsers.join(',')
    };

    Polyculy.createPersonalEvent(formData).done(function(resp) {
        if (resp.success) {
            bootstrap.Modal.getInstance(document.getElementById('personalEventModal')).hide();
            Polyculy.showAlert('Event created!', 'success');
            Polyculy.renderCalendar();
        } else {
            Polyculy.showAlert(resp.message || 'Error creating event.', 'error');
        }
    });
}
</script>
</cfoutput>
</cf_main>
