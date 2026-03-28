<cf_main pageTitle="Invite to Shared Event" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="page-header">
        <h2 class="page-title"><i class="fas fa-share-alt me-2"></i>Invite to Shared Event</h2>
    </div>

    <div class="card-polyculy" style="max-width:800px;">
        <!--- Section: Event Details --->
        <div class="accordion-section active" id="seDetailsSection">
            <div class="card-header-poly accordion-header" onclick="toggleSection('seDetailsSection')">
                <h5><i class="fas fa-chevron-down me-2"></i>Event Details</h5>
            </div>
            <div class="card-body-poly accordion-body">
                <div class="mb-3">
                    <label class="form-label-poly">Title <span class="text-danger">*</span></label>
                    <input type="text" class="form-control" id="seTitle" placeholder="e.g., Dinner with Riley" required>
                </div>
                <div class="row g-2 mb-3">
                    <div class="col-md-4">
                        <label class="form-label-poly">Start Date <span class="text-danger">*</span></label>
                        <input type="date" class="form-control" id="seStartDate" required>
                    </div>
                    <div class="col-md-2"><label class="form-label-poly">Hour</label>
                        <select class="form-select" id="seStartHour"><cfloop from="1" to="12" index="h"><option value="#h#"<cfif h eq 8> selected</cfif>>#h#</option></cfloop></select>
                    </div>
                    <div class="col-md-2"><label class="form-label-poly">Min</label>
                        <select class="form-select" id="seStartMinute"><option value="00">00</option><option value="15">15</option><option value="30">30</option><option value="45">45</option></select>
                    </div>
                    <div class="col-md-2"><label class="form-label-poly">AM/PM</label>
                        <select class="form-select" id="seStartAmPm"><option value="AM">AM</option><option value="PM" selected>PM</option></select>
                    </div>
                    <div class="col-md-2 d-flex align-items-end">
                        <div class="form-check"><input class="form-check-input" type="checkbox" id="seAllDay"><label class="form-check-label" for="seAllDay">All Day</label></div>
                    </div>
                </div>
                <div class="row g-2 mb-3" id="seEndRow">
                    <div class="col-md-4"><label class="form-label-poly">End Date</label><input type="date" class="form-control" id="seEndDate"></div>
                    <div class="col-md-2"><label class="form-label-poly">Hour</label>
                        <select class="form-select" id="seEndHour"><cfloop from="1" to="12" index="h"><option value="#h#"<cfif h eq 9> selected</cfif>>#h#</option></cfloop></select>
                    </div>
                    <div class="col-md-2"><label class="form-label-poly">Min</label>
                        <select class="form-select" id="seEndMinute"><option value="00">00</option><option value="15">15</option><option value="30">30</option><option value="45">45</option></select>
                    </div>
                    <div class="col-md-2"><label class="form-label-poly">AM/PM</label>
                        <select class="form-select" id="seEndAmPm"><option value="AM">AM</option><option value="PM" selected>PM</option></select>
                    </div>
                </div>
                <div class="mb-3"><label class="form-label-poly">Event Details</label><textarea class="form-control" id="seDetails" rows="2"></textarea></div>
                <div class="mb-3"><label class="form-label-poly">Address</label><input type="text" class="form-control" id="seAddress"></div>
                <div class="row g-2 mb-3">
                    <div class="col-md-4">
                        <label class="form-label-poly">Reminder</label>
                        <select class="form-select" id="seReminder"><option value="">None</option><option value="5">5 min</option><option value="15" selected>15 min</option><option value="30">30 min</option><option value="60">1 hour</option></select>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label-poly">Reminder Scope</label>
                        <div class="view-toggle-group mt-1">
                            <button class="view-toggle-btn active" data-scope="me" onclick="setReminderScope('me')">Me</button>
                            <button class="view-toggle-btn" data-scope="all" onclick="setReminderScope('all')">All</button>
                        </div>
                    </div>
                    <div class="col-md-4">
                        <label class="form-label-poly">Participant Visibility</label>
                        <div class="view-toggle-group mt-1">
                            <button class="view-toggle-btn active" data-pvis="visible" onclick="setParticipantVis('visible')">Visible to all</button>
                            <button class="view-toggle-btn" data-pvis="hidden" onclick="setParticipantVis('hidden')">Hidden</button>
                        </div>
                    </div>
                </div>
            </div>
        </div>

        <!--- Section: Invite Others --->
        <div class="accordion-section" id="seInviteSection">
            <div class="card-header-poly accordion-header" onclick="toggleSection('seInviteSection')">
                <h5><i class="fas fa-chevron-right me-2"></i>Invite Others <span class="text-danger">*</span></h5>
            </div>
            <div class="card-body-poly accordion-body" style="display:none;">
                <div class="d-flex gap-3 mb-3">
                    <div class="form-check">
                        <input class="form-check-input" type="radio" name="inviteMode" id="inviteAll" value="all">
                        <label class="form-check-label" for="inviteAll">All</label>
                    </div>
                    <div class="form-check">
                        <input class="form-check-input" type="radio" name="inviteMode" id="inviteSelect" value="select" checked>
                        <label class="form-check-label" for="inviteSelect">Select</label>
                    </div>
                </div>

                <div id="participantList">
                    <div class="text-muted py-2"><i class="fas fa-spinner fa-spin"></i> Loading connected members...</div>
                </div>

                <!--- Conflict Warning --->
                <div class="conflict-panel" id="conflictPanel" style="display:none;">
                    <div class="conflict-header"><i class="fas fa-exclamation-triangle me-1"></i> Time Conflict Detected</div>
                    <div id="conflictDetails"></div>
                    <div class="form-check mt-2">
                        <input class="form-check-input" type="checkbox" id="conflictAck">
                        <label class="form-check-label">I understand that I am requesting a time they may be busy.</label>
                    </div>
                </div>
            </div>
        </div>

        <div class="card-body-poly">
            <div class="d-flex gap-2">
                <a href="/views/calendar/month.cfm" class="btn btn-outline-secondary">Cancel</a>
                <button class="btn btn-primary-purple" onclick="sendSharedEvent()">
                    <i class="fas fa-paper-plane me-1"></i>Send Invites
                </button>
            </div>
        </div>
    </div>
</div>

<script>
var reminderScope = 'me';
var participantVisibility = 'visible';

$(document).ready(function() {
    var today = Polyculy.formatDateISO(new Date());
    $('##seStartDate').val(today);
    $('##seEndDate').val(today);
    loadInvitePeople();
    $('input[name="inviteMode"]').on('change', function() {
        if ($(this).val() === 'all') {
            $('.invite-check').prop('checked', true).prop('disabled', true);
            $('.attendance-toggle').prop('disabled', false);
        } else {
            $('.invite-check').prop('checked', false).prop('disabled', false);
            $('.attendance-toggle').prop('disabled', true);
        }
    });
});

function toggleSection(sectionId) {
    var $section = $('##' + sectionId);
    var $body = $section.find('.accordion-body');
    var $icon = $section.find('.accordion-header .fas');
    if ($section.hasClass('active')) {
        $section.removeClass('active'); $body.slideUp(200);
        $icon.removeClass('fa-chevron-down').addClass('fa-chevron-right');
    } else {
        $section.addClass('active'); $body.slideDown(200);
        $icon.removeClass('fa-chevron-right').addClass('fa-chevron-down');
    }
}

function setReminderScope(scope) {
    reminderScope = scope;
    $('[data-scope]').removeClass('active');
    $('[data-scope="' + scope + '"]').addClass('active');
}

function setParticipantVis(vis) {
    participantVisibility = vis;
    $('[data-pvis]').removeClass('active');
    $('[data-pvis="' + vis + '"]').addClass('active');
}

function loadInvitePeople() {
    Polyculy.loadConnectedMembers().done(function(resp) {
        if (!resp.success) return;
        var html = '';
        var colors = ['##22C55E','##3B82F6','##F59E0B','##A855F7','##EC4899','##06B6D4','##EF4444'];
        (resp.data || []).forEach(function(m, i) {
            html += '<div class="invite-row">' +
                '<span class="invite-color" style="background:' + (m.calendarcolor || colors[i % colors.length]) + ';"></span>' +
                '<div class="form-check flex-grow-1">' +
                '<input class="form-check-input invite-check" type="checkbox" value="' + m.userid + '" id="inv_' + m.userid + '" onchange="onInviteCheck(this)">' +
                '<label class="form-check-label invite-name" for="inv_' + m.userid + '">' + Polyculy.escapeHtml(m.displayname) + '</label></div>' +
                '<div class="view-toggle-group attendance-toggle" style="font-size:0.75rem;" data-uid="' + m.userid + '">' +
                '<button class="view-toggle-btn active btn-xs" data-att="required" onclick="setAttendance(' + m.userid + ',\'required\',this)" disabled>Required</button>' +
                '<button class="view-toggle-btn btn-xs" data-att="optional" onclick="setAttendance(' + m.userid + ',\'optional\',this)" disabled>Optional</button>' +
                '</div></div>';
        });
        $('##participantList').html(html || '<div class="text-muted">No connected members to invite.</div>');
    });
}

function onInviteCheck(el) {
    var uid = $(el).val();
    var $toggle = $('.attendance-toggle[data-uid="' + uid + '"] button');
    if (el.checked) { $toggle.prop('disabled', false); }
    else { $toggle.prop('disabled', true); }
}

function setAttendance(uid, type, btn) {
    $(btn).closest('.attendance-toggle').find('.view-toggle-btn').removeClass('active');
    $(btn).addClass('active');
}

function sendSharedEvent() {
    var title = $('##seTitle').val().trim();
    if (!title) { Polyculy.showAlert('Title is required.', 'error'); return; }

    var participants = [];
    var formData = {
        title: title,
        startDate: $('##seStartDate').val(),
        startHour: $('##seStartHour').val(),
        startMinute: $('##seStartMinute').val(),
        startAmPm: $('##seStartAmPm').val(),
        endDate: $('##seEndDate').val() || $('##seStartDate').val(),
        endHour: $('##seEndHour').val(),
        endMinute: $('##seEndMinute').val(),
        endAmPm: $('##seEndAmPm').val(),
        allDay: $('##seAllDay').is(':checked') ? 'on' : '',
        eventDetails: $('##seDetails').val(),
        address: $('##seAddress').val(),
        reminderMinutes: $('##seReminder').val(),
        reminderScope: reminderScope,
        participantVisibility: participantVisibility
    };

    $('.invite-check:checked').each(function() {
        var uid = $(this).val();
        participants.push(uid);
        var att = $('.attendance-toggle[data-uid="' + uid + '"] .active').data('att') || 'required';
        formData['attendance_' + uid] = att;
    });

    if (participants.length === 0) {
        Polyculy.showAlert('Please select at least one participant.', 'error');
        return;
    }
    formData.participants = participants.join(',');

    Polyculy.createSharedEvent(formData).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('Invitations sent!', 'success');
            setTimeout(function() { window.location.href = '/views/calendar/month.cfm'; }, 1500);
        } else {
            Polyculy.showAlert(resp.message || 'Error.', 'error');
        }
    });
}
</script>
</cfoutput>
</cf_main>
