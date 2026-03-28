<cf_main pageTitle="Create Your Personal Calendar" showNav="true">
<cfoutput>
<div class="page-container">
    <div class="page-header text-center">
        <h2 class="page-title">Create Your Personal Calendar</h2>
        <p class="page-subtitle">Choose how you'd like to set up your calendar. You can start fresh, or bring in events from an existing calendar.</p>
        <p class="text-muted-sm">Your calendar will be used to coordinate plans with your polycule.</p>
    </div>

    <div class="row g-4 justify-content-center" style="max-width:900px;margin:0 auto;">
        <!--- Start From Scratch --->
        <div class="col-md-4">
            <div class="setup-card">
                <div class="setup-icon">
                    <i class="fas fa-calendar-plus"></i>
                </div>
                <h5>Start From Scratch</h5>
                <p>Create a brand new calendar and begin adding events manually.</p>
                <button class="btn btn-primary-purple w-100" onclick="setupCalendar('scratch')">
                    Create Empty Calendar
                </button>
            </div>
        </div>

        <!--- Upload Calendar File --->
        <div class="col-md-4">
            <div class="setup-card">
                <div class="setup-icon">
                    <i class="fas fa-file-upload"></i>
                </div>
                <h5>Upload Calendar File</h5>
                <p>Import events from a calendar file such as .ics.</p>
                <button class="btn btn-outline-purple w-100" onclick="showIcsUpload()">
                    <i class="fas fa-upload me-1"></i>Upload File
                </button>
                <p class="text-muted-sm mt-1" style="font-size:0.7rem;">Supported format: .ics</p>
            </div>
        </div>

        <!--- Import from Google Calendar --->
        <div class="col-md-4">
            <div class="setup-card">
                <div class="setup-icon">
                    <i class="fab fa-google"></i>
                </div>
                <h5>Import from Google Calendar</h5>
                <p>Connect your Google account to import events from your existing Google Calendar.</p>
                <button class="btn btn-primary-purple w-100" onclick="connectGoogle()">
                    <i class="fab fa-google me-1"></i>Connect Google Calendar
                </button>
                <p class="text-muted-sm mt-1" style="font-size:0.7rem;">You'll be asked to authorize access to your Google Calendar.</p>
            </div>
        </div>
    </div>
</div>

<script>
function setupCalendar(method) {
    Polyculy.setupCalendar(method).done(function(resp) {
        if (resp.success) {
            Polyculy.showAlert('Calendar created!', 'success');
            setTimeout(function() {
                window.location.href = '/views/calendar/month.cfm';
            }, 1000);
        } else {
            Polyculy.showAlert(resp.message || 'Error creating calendar.', 'error');
        }
    });
}

function showIcsUpload() {
    Polyculy.showModal('Upload Calendar File',
        '<p>Calendar import (.ics) backend is available in Phase 2. For now, please start with an empty calendar and add events manually.</p>' +
        '<p class="text-muted-sm">You can export your calendar as .ics from Settings once you have events.</p>',
        '<button class="btn btn-primary-purple" onclick="setupCalendar(\'ics\')">Start With Empty Calendar Instead</button>');
}

function connectGoogle() {
    Polyculy.showModal('Google Calendar Sync',
        '<p>Two-way Google Calendar sync is available in Phase 2. For now, please start with an empty calendar.</p>' +
        '<p class="text-muted-sm">This feature will allow you to connect your Google account and import existing events.</p>',
        '<button class="btn btn-primary-purple" onclick="setupCalendar(\'google\')">Start With Empty Calendar Instead</button>');
}
</script>
</cfoutput>
</cf_main>
