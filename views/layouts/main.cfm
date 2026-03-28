<cfif thistag.executionMode eq "start">
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Polyculy - <cfoutput>#attributes.pageTitle ?: "Calendar that keeps up"#</cfoutput></title>

    <!-- Bootstrap 5.3 -->
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <!-- Font Awesome 6 -->
    <link href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.5.1/css/all.min.css" rel="stylesheet">
    <!-- DataTables Bootstrap 5 -->
    <link href="https://cdn.datatables.net/1.13.8/css/dataTables.bootstrap5.min.css" rel="stylesheet">
    <!-- Chosen -->
    <link href="https://cdnjs.cloudflare.com/ajax/libs/chosen/1.8.7/chosen.min.css" rel="stylesheet">
    <!-- Google Fonts -->
    <link href="https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap" rel="stylesheet">
    <!-- Polyculy Custom -->
    <link href="/assets/css/polyculy.css" rel="stylesheet">

    <!-- jQuery -->
    <script src="https://code.jquery.com/jquery-3.7.1.min.js"></script>
    <!-- Bootstrap JS -->
    <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/js/bootstrap.bundle.min.js"></script>
    <!-- DataTables -->
    <script src="https://cdn.datatables.net/1.13.8/js/jquery.dataTables.min.js"></script>
    <script src="https://cdn.datatables.net/1.13.8/js/dataTables.bootstrap5.min.js"></script>
    <!-- Chosen -->
    <script src="https://cdnjs.cloudflare.com/ajax/libs/chosen/1.8.7/chosen.jquery.min.js"></script>
    <!-- Chart.js -->
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.1/dist/chart.umd.min.js"></script>
    <!-- Polyculy JS -->
    <script src="/assets/js/polyculy.js"></script>
</head>
<body>
    <cfoutput>
    <!-- Top Navbar -->
    <cfif isDefined("session.userID") AND val(session.userID) GT 0>
	   	<nav class="navbar-polyculy">
	        <div class="navbar-brand-area">
	            <a href="/views/calendar/month.cfm" class="navbar-brand-link">
	                <svg class="logo-icon" width="36" height="36" viewBox="0 0 40 40" fill="none">
	                    <path d="M12 8C7 8 3 12 3 17C3 27 20 36 20 36C20 36 37 27 37 17C37 12 33 8 28 8C24.5 8 21.5 10 20 13C18.5 10 15.5 8 12 8Z" fill="url(##heartGrad1)" opacity="0.7"/>
	                    <path d="M15 6C10 6 6 10 6 15C6 25 23 34 23 34C23 34 40 25 40 15C40 10 36 6 31 6C27.5 6 24.5 8 23 11C21.5 8 18.5 6 15 6Z" fill="url(##heartGrad2)" opacity="0.8"/>
	                    <defs>
	                        <linearGradient id="heartGrad1" x1="3" y1="8" x2="37" y2="36" gradientUnits="userSpaceOnUse">
	                            <stop stop-color="##EC4899"/><stop offset="1" stop-color="##8B5CF6"/>
	                        </linearGradient>
	                        <linearGradient id="heartGrad2" x1="6" y1="6" x2="40" y2="34" gradientUnits="userSpaceOnUse">
	                            <stop stop-color="##A855F7"/><stop offset="1" stop-color="##7C3AED"/>
	                        </linearGradient>
	                    </defs>
	                </svg>
	                <span class="brand-text">Polyculy</span>
	            </a>
	        </div>
	        <div class="navbar-actions">
	            <cfif structKeyExists(attributes, "showNav") && attributes.showNav>
	                <a href="/views/connections/connect.cfm" class="nav-action-link" title="Polycule" data-testid="nav-polycule">
	                    <i class="fas fa-users"></i>
	                </a>
	                <a href="/views/settings/timezone.cfm" class="nav-action-link" title="Settings" data-testid="nav-settings">
	                    <i class="fas fa-cog"></i>
	                </a>
	                <div class="notification-bell" id="notificationBell" data-testid="notification-bell" onclick="Polyculy.toggleNotifications()">
	                    <i class="fas fa-bell"></i>
	                    <span class="notification-badge" id="notifBadge" data-testid="notification-badge" style="display:none;">0</span>
	                </div>
	                <div class="notification-panel" id="notificationPanel" data-testid="notification-panel" style="display:none;">
	                    <div class="notif-header">
	                        <strong>Notifications</strong>
	                        <a href="##" onclick="Polyculy.markAllNotificationsRead(); return false;">Mark all read</a>
	                    </div>
	                    <div class="notif-list" id="notifList" data-testid="notification-list">
	                        <div class="text-center text-muted py-3"><i class="fas fa-spinner fa-spin"></i></div>
	                    </div>
	                </div>
	                <div class="user-avatar-nav" title="#session.displayName#">
	                    <span class="avatar-initials">#uCase(left(session.displayName, 1))#</span>
	                </div>
	                <a href="##" onclick="Polyculy.logout(); return false;" class="nav-action-link" title="Logout" data-testid="nav-logout">
	                    <i class="fas fa-sign-out-alt"></i>
	                </a>
	            </cfif>
	        </div>
	    </nav>  	
    </cfif>	
 
    </cfoutput>

    <!-- Notification Overlay (click outside to close) -->
    <div class="notif-overlay" id="notifOverlay" style="display:none;" onclick="Polyculy.toggleNotifications()"></div>

    <!-- Main Content -->
    <div class="main-content">

<cfelseif thistag.executionMode eq "end">

    </div>

    <footer class="app-footer">
<!---         <a href="https://www.perplexity.ai/computer" target="_blank" rel="noopener noreferrer">
            Created with Perplexity Computer
        </a>&middot; --->
         Polyculy &copy; <cfoutput>#year(now())#</cfoutput>
    </footer>

</body>
</html>
</cfif>
