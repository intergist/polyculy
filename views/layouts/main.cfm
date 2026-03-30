<cfif thistag.executionMode eq "start">
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Polyculy - <cfoutput>#attributes.pageTitle ?: "Calendar that keeps up"#</cfoutput></title>
    <link rel="icon" type="image/x-icon" href="/favicon.ico">

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
   
    <!-- Top Navbar -->
    <cfif isDefined("session.userID") AND val(session.userID) GT 0> <cfoutput>
	   	<nav class="navbar-polyculy">
	        <div class="navbar-brand-area">
	            <a href="/views/calendar/month.cfm" class="navbar-brand-link">
					<img src="/images/polyculy_logo_xs.png" width="40" height="32" title="Polyculy"/>
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
	    </nav>  </cfoutput>
	    
	        <!-- Notification Overlay (click outside to close) -->
    <div class="notif-overlay" id="notifOverlay" style="display:none;" onclick="Polyculy.toggleNotifications()"></div>

    
	     	
    </cfif>	
 
   

<!-- Main Content -->
  <!---   <div class="main-content">--->

<cfelseif thistag.executionMode eq "end">

  <!---   </div>--->

    <footer class="app-footer">
<!---         <a href="https://www.perplexity.ai/computer" target="_blank" rel="noopener noreferrer">
            Created with Perplexity Computer
        </a>&middot; --->
         Polyculy &copy; <cfoutput>#year(now())#</cfoutput>
    </footer>

    <cfif isDefined("session.userID") AND val(session.userID) GT 0>
// Init on page load
$(document).ready(function() {
   Polyculy.loadNotificationCount();
    // Refresh notification count every 30 seconds
   setInterval(Polyculy.loadNotificationCount, 30000);
});
    </cfif>

</body>
</html>
</cfif>
