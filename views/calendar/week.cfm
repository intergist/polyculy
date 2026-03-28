<cf_main pageTitle="My Calendar - Week View" showNav="true">
<cfoutput>
<div class="page-container calendar-page">
    <div class="calendar-header">
        <div class="calendar-header-left">
            <h2 class="page-title">My Calendar</h2>
        </div>
        <div class="calendar-header-actions">
            <button class="btn btn-primary-purple btn-sm" onclick="window.location.href='/views/calendar/month.cfm'">
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
            <button class="view-toggle-btn active" data-view="week" data-testid="view-week" onclick="Polyculy.setView('week')">Week</button>
            <button class="view-toggle-btn" data-view="month" data-testid="view-month" onclick="Polyculy.setView('month')">Month</button>
        </div>
        <div class="calendar-nav">
            <button class="btn-nav" onclick="Polyculy.navigateCalendar(-1)"><i class="fas fa-chevron-left"></i></button>
            <span class="calendar-nav-title" id="calendarTitle" data-testid="calendar-nav-title">Loading...</span>
            <button class="btn-nav" onclick="Polyculy.navigateCalendar(1)"><i class="fas fa-chevron-right"></i></button>
        </div>
        <div class="view-toggle-group">
            <button class="view-toggle-btn active" data-perspective="mine" data-testid="perspective-mine" onclick="Polyculy.setPerspective('mine')">Mine</button>
            <button class="view-toggle-btn" data-perspective="our" data-testid="perspective-our" onclick="Polyculy.setPerspective('our')">Our</button>
        </div>
    </div>

    <div class="calendar-grid week-view" id="calendarGrid" data-testid="calendar-grid">
        <div class="text-center text-muted py-5"><i class="fas fa-spinner fa-spin fa-2x"></i></div>
    </div>

    <div class="toggle-bar" id="toggleBar" data-testid="toggle-bar" style="display:none;"></div>
</div>

<script>
$(document).ready(function() {
    Polyculy.setView('week');
    Polyculy.initCalendar();
});
</script>
</cfoutput>
</cf_main>
