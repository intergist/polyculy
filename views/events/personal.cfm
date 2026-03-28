<cf_main pageTitle="Personal Events" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="page-header">
        <h2 class="page-title"><i class="fas fa-calendar me-2"></i>My Personal Events</h2>
        <button class="btn btn-primary-purple btn-sm" onclick="window.location.href='/views/calendar/month.cfm'">
            <i class="fas fa-plus me-1"></i>Add Personal Event
        </button>
    </div>

    <div class="card-polyculy">
        <div class="card-body-poly">
            <div class="table-responsive">
                <table class="table table-polyculy" id="personalEventsTable">
                    <thead>
                        <tr>
                            <th>Title</th>
                            <th>Date</th>
                            <th>Time</th>
                            <th>Visibility</th>
                            <th>Actions</th>
                        </tr>
                    </thead>
                    <tbody id="eventsBody">
                        <tr><td colspan="5" class="text-center"><i class="fas fa-spinner fa-spin"></i> Loading...</td></tr>
                    </tbody>
                </table>
            </div>
        </div>
    </div>
</div>

<script>
$(document).ready(function() {
    loadPersonalEvents();
});

function loadPersonalEvents() {
    Polyculy.apiGet('/api/events.cfm?action=list').done(function(resp) {
        if (!resp.success) return;
        var events = resp.data || [];
        if (events.length === 0) {
            $('##eventsBody').html('<tr><td colspan="5" class="text-center text-muted">No personal events yet.</td></tr>');
            return;
        }
        var html = '';
        events.forEach(function(ev) {
            var visLabel = ev.visibility_tier || 'invisible';
            if (visLabel === 'invisible') visLabel = '<span class="text-muted">Private</span>';
            else if (visLabel === 'full_details') visLabel = '<span class="text-success">Full Details</span>';
            else visLabel = '<span class="text-info">Busy Block</span>';

            html += '<tr>' +
                '<td><strong>' + Polyculy.escapeHtml(ev.title) + '</strong></td>' +
                '<td>' + Polyculy.formatDateTime(ev.start_time) + '</td>' +
                '<td>' + Polyculy.formatTime(ev.start_time) + (ev.end_time ? ' - ' + Polyculy.formatTime(ev.end_time) : '') + '</td>' +
                '<td>' + visLabel + '</td>' +
                '<td>' +
                '<button class="btn btn-sm btn-outline-purple me-1" onclick="Polyculy.showEventDetail(\'personal\',' + ev.event_id + ')"><i class="fas fa-eye"></i></button>' +
                '<button class="btn btn-sm btn-outline-danger" onclick="deleteEvent(' + ev.event_id + ')"><i class="fas fa-trash"></i></button>' +
                '</td></tr>';
        });
        $('##eventsBody').html(html);
        if ($.fn.DataTable) {
            $('##personalEventsTable').DataTable({ destroy: true, pageLength: 10, order: [[1, 'desc']] });
        }
    });
}

function deleteEvent(eventId) {
    if (!confirm('Delete this event?')) return;
    Polyculy.apiPost('/api/events.cfm?action=delete', { eventId: eventId }).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('Event deleted.', 'success');
            loadPersonalEvents();
        } else {
            Polyculy.showAlert(resp.message || 'Error.', 'error');
        }
    });
}
</script>
</cfoutput>
</cf_main>
