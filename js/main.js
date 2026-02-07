// OpenClaw Testing Hub - Main JavaScript
// Data storage
let findings = JSON.parse(localStorage.getItem('openclawFindings')) || [];
let codeSnippets = JSON.parse(localStorage.getItem('openclawSnippets')) || [];
let markdownNotes = JSON.parse(localStorage.getItem('openclawNotes')) || [];

// Initialize on page load
document.addEventListener('DOMContentLoaded', function() {
    initializeApp();
    loadFindings();
    loadCodeSnippets();
    loadMarkdownNotes();
    updateStats();
    
    // Save checklist state
    document.querySelectorAll('.checklist input[type="checkbox"]').forEach(checkbox => {
        const savedState = localStorage.getItem(`checkbox-${checkbox.id}`);
        if (savedState === 'true') {
            checkbox.checked = true;
        }
        
        checkbox.addEventListener('change', function() {
            localStorage.setItem(`checkbox-${this.id}`, this.checked);
            updateStats();
        });
    });

    // Form submission
    const findingForm = document.getElementById('finding-form');
    if (findingForm) {
        findingForm.addEventListener('submit', function(e) {
            e.preventDefault();
            saveFinding();
        });
    }

    // Smooth scrolling for navigation links
    document.querySelectorAll('a[href^="#"]').forEach(anchor => {
        anchor.addEventListener('click', function (e) {
            e.preventDefault();
            const target = document.querySelector(this.getAttribute('href'));
            if (target) {
                target.scrollIntoView({
                    behavior: 'smooth',
                    block: 'start'
                });
            }
        });
    });
});

function initializeApp() {
    console.log('OpenClaw Testing Hub initialized');
    console.log('Findings:', findings.length);
    console.log('Code Snippets:', codeSnippets.length);
    console.log('Markdown Notes:', markdownNotes.length);
}

// Test Status Management
function updateTestStatus(button, newStatus) {
    const row = button.closest('tr');
    const statusCell = row.querySelector('.status-badge');
    
    let statusText = '';
    let statusClass = 'status-pending';
    
    switch(newStatus) {
        case 'running':
            statusText = 'Running';
            statusClass = 'status-running';
            button.textContent = 'Mark Complete';
            button.onclick = () => updateTestStatus(button, 'passed');
            break;
        case 'passed':
            statusText = 'Passed';
            statusClass = 'status-passed';
            button.textContent = 'Reset';
            button.onclick = () => updateTestStatus(button, 'pending');
            break;
        case 'pending':
            statusText = 'Pending';
            statusClass = 'status-pending';
            button.textContent = 'Start Test';
            button.onclick = () => updateTestStatus(button, 'running');
            break;
    }
    
    statusCell.className = `status-badge ${statusClass}`;
    statusCell.textContent = statusText;
    
    updateStats();
}

// Statistics Update
function updateStats() {
    // Count completed tests
    const allTests = document.querySelectorAll('.status-badge');
    const completedTests = document.querySelectorAll('.status-passed').length;
    const passedTests = completedTests; // In this case, passed = completed
    
    // Count checked security items
    const checkedItems = document.querySelectorAll('.checklist input[type="checkbox"]:checked').length;
    
    // Update display
    document.getElementById('tests-completed').textContent = completedTests;
    document.getElementById('tests-passed').textContent = passedTests;
    document.getElementById('security-issues').textContent = findings.filter(f => f.category === 'security').length;
    document.getElementById('documentation-entries').textContent = codeSnippets.length + markdownNotes.length;
}

// Findings Management
function addFinding() {
    openModal('finding-modal');
}

function saveFinding() {
    const title = document.getElementById('finding-title').value;
    const severity = document.getElementById('finding-severity').value;
    const category = document.getElementById('finding-category').value;
    const description = document.getElementById('finding-description').value;
    
    const finding = {
        id: Date.now().toString(),
        title,
        severity,
        category,
        description,
        timestamp: new Date().toISOString()
    };
    
    findings.push(finding);
    localStorage.setItem('openclawFindings', JSON.stringify(findings));
    
    loadFindings();
    updateStats();
    closeModal();
    
    // Reset form
    document.getElementById('finding-form').reset();
}

function loadFindings() {
    const findingsList = document.getElementById('findings-list');
    
    if (findings.length === 0) {
        findingsList.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-clipboard"></i>
                <p>No findings yet. Start testing to populate this section.</p>
            </div>
        `;
        return;
    }
    
    findingsList.innerHTML = findings.map(finding => `
        <div class="finding-item severity-${finding.severity}">
            <div class="finding-header">
                <div class="finding-title">${escapeHtml(finding.title)}</div>
                <div class="finding-meta">
                    <span class="badge badge-priority-${finding.severity === 'critical' ? 'critical' : finding.severity === 'high' ? 'high' : 'medium'}">
                        ${finding.severity.toUpperCase()}
                    </span>
                    <span class="badge badge-info">${finding.category}</span>
                    <button class="btn-small btn-secondary" onclick="deleteFinding('${finding.id}')">
                        <i class="fas fa-trash"></i>
                    </button>
                </div>
            </div>
            <div class="finding-description">${escapeHtml(finding.description)}</div>
            <div class="finding-timestamp">
                <i class="fas fa-clock"></i> ${formatDate(finding.timestamp)}
            </div>
        </div>
    `).join('');
}

function deleteFinding(id) {
    if (confirm('Are you sure you want to delete this finding?')) {
        findings = findings.filter(f => f.id !== id);
        localStorage.setItem('openclawFindings', JSON.stringify(findings));
        loadFindings();
        updateStats();
    }
}

function exportFindings() {
    if (findings.length === 0) {
        alert('No findings to export yet.');
        return;
    }
    
    let markdown = `# OpenClaw Security Evaluation Findings\n\n`;
    markdown += `**Generated:** ${new Date().toLocaleString()}\n\n`;
    markdown += `**Total Findings:** ${findings.length}\n\n`;
    markdown += `---\n\n`;
    
    // Group by severity
    const severities = ['critical', 'high', 'medium', 'low', 'info'];
    severities.forEach(severity => {
        const severityFindings = findings.filter(f => f.severity === severity);
        if (severityFindings.length > 0) {
            markdown += `## ${severity.charAt(0).toUpperCase() + severity.slice(1)} Severity\n\n`;
            severityFindings.forEach(finding => {
                markdown += `### ${finding.title}\n\n`;
                markdown += `**Category:** ${finding.category}\n\n`;
                markdown += `**Severity:** ${finding.severity}\n\n`;
                markdown += `**Date:** ${formatDate(finding.timestamp)}\n\n`;
                markdown += `**Description:**\n\n${finding.description}\n\n`;
                markdown += `---\n\n`;
            });
        }
    });
    
    // Download as file
    downloadFile('openclaw-findings.md', markdown);
}

// Code Snippets Management
function showCodeEditor() {
    const snippet = prompt('Enter code snippet title:');
    if (!snippet) return;
    
    const language = prompt('Enter programming language (e.g., python, javascript, bash):');
    const code = prompt('Paste your code:');
    
    if (code) {
        const newSnippet = {
            id: Date.now().toString(),
            title: snippet,
            language: language || 'text',
            code: code,
            timestamp: new Date().toISOString()
        };
        
        codeSnippets.push(newSnippet);
        localStorage.setItem('openclawSnippets', JSON.stringify(codeSnippets));
        loadCodeSnippets();
        updateStats();
    }
}

function loadCodeSnippets() {
    const snippetList = document.getElementById('code-snippets');
    
    if (codeSnippets.length === 0) {
        snippetList.innerHTML = '<div class="empty-state"><p>No code snippets yet.</p></div>';
        return;
    }
    
    snippetList.innerHTML = codeSnippets.map(snippet => `
        <div class="snippet-item">
            <div class="snippet-title">${escapeHtml(snippet.title)}</div>
            <span class="snippet-language">${escapeHtml(snippet.language)}</span>
            <div class="code-block">
                <pre><code>${escapeHtml(snippet.code)}</code></pre>
            </div>
            <div style="margin-top: 0.5rem; display: flex; gap: 0.5rem;">
                <button class="btn-small btn-secondary" onclick="copyToClipboard(\`${escapeHtml(snippet.code).replace(/`/g, '\\`')}\`)">
                    <i class="fas fa-copy"></i> Copy
                </button>
                <button class="btn-small btn-secondary" onclick="deleteSnippet('${snippet.id}')">
                    <i class="fas fa-trash"></i> Delete
                </button>
            </div>
        </div>
    `).join('');
}

function deleteSnippet(id) {
    if (confirm('Delete this code snippet?')) {
        codeSnippets = codeSnippets.filter(s => s.id !== id);
        localStorage.setItem('openclawSnippets', JSON.stringify(codeSnippets));
        loadCodeSnippets();
        updateStats();
    }
}

// Markdown Notes Management
function showMarkdownEditor() {
    const title = prompt('Enter note title:');
    if (!title) return;
    
    const content = prompt('Enter your markdown note:');
    if (content) {
        const newNote = {
            id: Date.now().toString(),
            title: title,
            content: content,
            timestamp: new Date().toISOString()
        };
        
        markdownNotes.push(newNote);
        localStorage.setItem('openclawNotes', JSON.stringify(markdownNotes));
        loadMarkdownNotes();
        updateStats();
    }
}

function loadMarkdownNotes() {
    const notesList = document.getElementById('markdown-notes');
    
    if (markdownNotes.length === 0) {
        notesList.innerHTML = '<div class="empty-state"><p>No markdown notes yet.</p></div>';
        return;
    }
    
    notesList.innerHTML = markdownNotes.map(note => `
        <div class="note-item">
            <div class="note-title">${escapeHtml(note.title)}</div>
            <div style="color: var(--text-secondary); margin: 0.5rem 0; font-size: 0.875rem;">
                ${formatDate(note.timestamp)}
            </div>
            <div style="color: var(--text-secondary); white-space: pre-wrap; font-family: var(--font-mono); font-size: 0.875rem;">
                ${escapeHtml(note.content)}
            </div>
            <div style="margin-top: 0.5rem; display: flex; gap: 0.5rem;">
                <button class="btn-small btn-secondary" onclick="exportNote('${note.id}')">
                    <i class="fas fa-download"></i> Export
                </button>
                <button class="btn-small btn-secondary" onclick="deleteNote('${note.id}')">
                    <i class="fas fa-trash"></i> Delete
                </button>
            </div>
        </div>
    `).join('');
}

function deleteNote(id) {
    if (confirm('Delete this note?')) {
        markdownNotes = markdownNotes.filter(n => n.id !== id);
        localStorage.setItem('openclawNotes', JSON.stringify(markdownNotes));
        loadMarkdownNotes();
        updateStats();
    }
}

function exportNote(id) {
    const note = markdownNotes.find(n => n.id === id);
    if (note) {
        const content = `# ${note.title}\n\n${note.content}\n\n---\n*Created: ${formatDate(note.timestamp)}*`;
        downloadFile(`${note.title.replace(/\s+/g, '-').toLowerCase()}.md`, content);
    }
}

// Modal Management
function openModal(modalId) {
    const modal = document.getElementById(modalId);
    const overlay = document.getElementById('modal-overlay');
    
    if (modal) {
        modal.classList.add('active');
        overlay.classList.add('active');
    }
}

function closeModal() {
    document.querySelectorAll('.modal').forEach(modal => {
        modal.classList.remove('active');
    });
    document.getElementById('modal-overlay').classList.remove('active');
}

// Security Checklist Display
function showSecurityChecklist() {
    alert('Security Checklist:\n\n' +
          '✓ VM Isolation configured\n' +
          '✓ Test account created\n' +
          '✓ Network monitoring enabled\n' +
          '✓ Logging configured\n' +
          '✓ Backup/snapshot taken\n\n' +
          'Review the Security section above for detailed checklist.');
}

// Report Generation
function generateReport() {
    let report = `# OpenClaw Security Evaluation Report\n\n`;
    report += `**Generated:** ${new Date().toLocaleString()}\n`;
    report += `**Evaluator:** [Your Name]\n\n`;
    report += `---\n\n`;
    
    report += `## Executive Summary\n\n`;
    report += `This report documents the comprehensive security evaluation of OpenClaw, `;
    report += `an AI agent framework, conducted in an isolated VM environment.\n\n`;
    
    report += `### Statistics\n\n`;
    report += `- **Tests Completed:** ${document.getElementById('tests-completed').textContent}\n`;
    report += `- **Tests Passed:** ${document.getElementById('tests-passed').textContent}\n`;
    report += `- **Security Issues Found:** ${document.getElementById('security-issues').textContent}\n`;
    report += `- **Documentation Entries:** ${document.getElementById('documentation-entries').textContent}\n\n`;
    
    report += `## Methodology\n\n`;
    report += `### Environment Setup\n`;
    report += `- **Platform:** Mac Mini VM (UTM/Parallels)\n`;
    report += `- **OS:** Ubuntu 22.04 LTS\n`;
    report += `- **Isolation:** Network-isolated VM with monitoring\n`;
    report += `- **Test Account:** Dedicated Gmail account (no personal data)\n\n`;
    
    report += `### Testing Approach\n`;
    report += `1. Functional capability testing\n`;
    report += `2. Security boundary testing\n`;
    report += `3. API integration testing\n`;
    report += `4. Privilege escalation attempts\n`;
    report += `5. Data exfiltration monitoring\n\n`;
    
    report += `## Findings\n\n`;
    
    if (findings.length > 0) {
        const severities = ['critical', 'high', 'medium', 'low', 'info'];
        severities.forEach(severity => {
            const severityFindings = findings.filter(f => f.severity === severity);
            if (severityFindings.length > 0) {
                report += `### ${severity.charAt(0).toUpperCase() + severity.slice(1)} Severity Findings\n\n`;
                severityFindings.forEach((finding, idx) => {
                    report += `#### ${idx + 1}. ${finding.title}\n\n`;
                    report += `**Category:** ${finding.category}\n\n`;
                    report += `${finding.description}\n\n`;
                });
            }
        });
    } else {
        report += `No findings documented yet. Testing is in progress.\n\n`;
    }
    
    report += `## Recommendations\n\n`;
    report += `1. Continue monitoring agent behavior in isolated environment\n`;
    report += `2. Document all API calls and data access patterns\n`;
    report += `3. Test with progressively less restrictive permissions\n`;
    report += `4. Evaluate potential for production use cases\n`;
    report += `5. Review security boundaries and access controls\n\n`;
    
    report += `## Conclusion\n\n`;
    report += `[Add your conclusions here after completing testing]\n\n`;
    
    report += `---\n\n`;
    report += `*This report was generated using the OpenClaw Testing Hub*\n`;
    
    downloadFile('openclaw-evaluation-report.md', report);
}

// Utility Functions
function escapeHtml(text) {
    const div = document.createElement('div');
    div.textContent = text;
    return div.innerHTML;
}

function formatDate(isoString) {
    const date = new Date(isoString);
    return date.toLocaleString('en-US', {
        year: 'numeric',
        month: 'short',
        day: 'numeric',
        hour: '2-digit',
        minute: '2-digit'
    });
}

function copyToClipboard(text) {
    navigator.clipboard.writeText(text).then(() => {
        alert('Copied to clipboard!');
    }).catch(err => {
        console.error('Failed to copy:', err);
    });
}

function downloadFile(filename, content) {
    const blob = new Blob([content], { type: 'text/markdown' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = filename;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
}

// Export data for backup
function exportAllData() {
    const allData = {
        findings,
        codeSnippets,
        markdownNotes,
        exportDate: new Date().toISOString()
    };
    
    const json = JSON.stringify(allData, null, 2);
    downloadFile('openclaw-testing-data.json', json);
}

// Import data from backup
function importData() {
    const input = document.createElement('input');
    input.type = 'file';
    input.accept = '.json';
    
    input.onchange = (e) => {
        const file = e.target.files[0];
        const reader = new FileReader();
        
        reader.onload = (event) => {
            try {
                const data = JSON.parse(event.target.result);
                
                if (confirm('This will overwrite current data. Continue?')) {
                    findings = data.findings || [];
                    codeSnippets = data.codeSnippets || [];
                    markdownNotes = data.markdownNotes || [];
                    
                    localStorage.setItem('openclawFindings', JSON.stringify(findings));
                    localStorage.setItem('openclawSnippets', JSON.stringify(codeSnippets));
                    localStorage.setItem('openclawNotes', JSON.stringify(markdownNotes));
                    
                    loadFindings();
                    loadCodeSnippets();
                    loadMarkdownNotes();
                    updateStats();
                    
                    alert('Data imported successfully!');
                }
            } catch (err) {
                alert('Error importing data: ' + err.message);
            }
        };
        
        reader.readAsText(file);
    };
    
    input.click();
}

// Keyboard shortcuts
document.addEventListener('keydown', function(e) {
    // Ctrl/Cmd + K to open add finding modal
    if ((e.ctrlKey || e.metaKey) && e.key === 'k') {
        e.preventDefault();
        addFinding();
    }
    
    // Escape to close modals
    if (e.key === 'Escape') {
        closeModal();
    }
});

console.log('OpenClaw Testing Hub loaded successfully');
console.log('Keyboard shortcuts:');
console.log('- Ctrl/Cmd + K: Add new finding');
console.log('- Escape: Close modal');
// =============================================================================
// COST TRACKING FUNCTIONALITY (Phase 2a)
// =============================================================================

// Cost Tracker API Base URL
const COST_TRACKER_URL = window.location.hostname === 'localhost' 
    ? 'http://localhost:5003' 
    : `http://${window.location.hostname}:5003`;

// Auto-refresh cost data
let costRefreshInterval = null;

// Initialize cost tracking when page loads
document.addEventListener('DOMContentLoaded', function() {
    // Check if cost tracker is available
    checkCostTrackerHealth();
    
    // Start auto-refresh (every 5 seconds)
    startCostAutoRefresh();
});

async function checkCostTrackerHealth() {
    try {
        const response = await fetch(`${COST_TRACKER_URL}/health`);
        if (response.ok) {
            console.log('✅ Cost Tracker connected');
            refreshCostData();
        } else {
            console.warn('⚠️ Cost Tracker unhealthy');
            showCostTrackerOffline();
        }
    } catch (error) {
        console.warn('⚠️ Cost Tracker not available:', error.message);
        showCostTrackerOffline();
    }
}

function showCostTrackerOffline() {
    const alertsDiv = document.getElementById('cost-alerts');
    if (alertsDiv) {
        alertsDiv.innerHTML = `
            <div class="alert alert-warning">
                <i class="fas fa-exclamation-triangle"></i>
                <div>
                    <strong>Cost Tracker Offline</strong><br>
                    The cost tracking service is not running. Start it with:<br>
                    <code>docker-compose up -d cost-tracker</code>
                </div>
            </div>
        `;
    }
}

async function refreshCostData() {
    try {
        // Fetch current statistics
        const statsResponse = await fetch(`${COST_TRACKER_URL}/stats`);
        if (!statsResponse.ok) {
            throw new Error('Failed to fetch stats');
        }
        
        const stats = await statsResponse.json();
        updateCostDisplay(stats);
        
        // Fetch alerts
        const alertsResponse = await fetch(`${COST_TRACKER_URL}/alerts`);
        if (alertsResponse.ok) {
            const alertsData = await alertsResponse.json();
            updateAlertsDisplay(alertsData.alerts);
        }
        
    } catch (error) {
        console.error('Error refreshing cost data:', error);
    }
}

function updateCostDisplay(stats) {
    // Session Budget
    updateBudgetCard('session', stats.session);
    
    // Hourly Budget
    updateBudgetCard('hourly', stats.hourly);
    
    // Daily Budget
    updateBudgetCard('daily', stats.daily);
    
    // Rate Limiting
    updateRateLimitDisplay(stats.rate);
    
    // Token Usage
    updateTokenDisplay(stats.tokens);
    
    // Projections
    updateProjections(stats);
}

function updateBudgetCard(type, data) {
    // Update cost value
    const costEl = document.getElementById(`${type}-cost`);
    if (costEl) {
        costEl.textContent = `$${data.cost.toFixed(2)}`;
        
        // Color code based on percentage
        if (data.percent >= 90) {
            costEl.style.color = '#e74c3c';
        } else if (data.percent >= 80) {
            costEl.style.color = '#f39c12';
        } else {
            costEl.style.color = '#2ecc71';
        }
    }
    
    // Update limit
    const limitEl = document.getElementById(`${type}-limit`);
    if (limitEl) {
        limitEl.textContent = `of $${data.budget.toFixed(2)}`;
    }
    
    // Update progress bar
    const progressEl = document.getElementById(`${type}-progress`);
    if (progressEl) {
        progressEl.style.width = `${Math.min(data.percent, 100)}%`;
        
        // Color code progress bar
        if (data.percent >= 90) {
            progressEl.style.backgroundColor = '#e74c3c';
        } else if (data.percent >= 80) {
            progressEl.style.backgroundColor = '#f39c12';
        } else {
            progressEl.style.backgroundColor = '#2ecc71';
        }
    }
    
    // Update session calls (if applicable)
    if (type === 'session') {
        const callsEl = document.getElementById('session-calls');
        if (callsEl) {
            callsEl.textContent = data.calls || 0;
        }
    }
}

function updateRateLimitDisplay(rateData) {
    const currentEl = document.getElementById('rate-current');
    if (currentEl) {
        currentEl.textContent = rateData.calls_this_minute || 0;
    }
    
    const maxEl = document.getElementById('rate-max');
    if (maxEl) {
        maxEl.textContent = rateData.max_per_minute || 30;
    }
    
    const remainingEl = document.getElementById('rate-remaining');
    if (remainingEl) {
        const remaining = rateData.max_per_minute - rateData.calls_this_minute;
        remainingEl.textContent = remaining;
    }
    
    const progressEl = document.getElementById('rate-progress');
    if (progressEl) {
        const percent = (rateData.calls_this_minute / rateData.max_per_minute) * 100;
        progressEl.style.width = `${Math.min(percent, 100)}%`;
        
        if (percent >= 90) {
            progressEl.style.backgroundColor = '#e74c3c';
        } else if (percent >= 80) {
            progressEl.style.backgroundColor = '#f39c12';
        } else {
            progressEl.style.backgroundColor = '#3498db';
        }
    }
}

function updateTokenDisplay(tokenData) {
    const inputEl = document.getElementById('tokens-input');
    if (inputEl) {
        inputEl.textContent = (tokenData.input || 0).toLocaleString();
    }
    
    const outputEl = document.getElementById('tokens-output');
    if (outputEl) {
        outputEl.textContent = (tokenData.output || 0).toLocaleString();
    }
    
    const totalEl = document.getElementById('tokens-total');
    if (totalEl) {
        totalEl.textContent = (tokenData.total || 0).toLocaleString();
    }
}

function updateProjections(stats) {
    const avgCostEl = document.getElementById('proj-avg-cost');
    if (avgCostEl && stats.session) {
        avgCostEl.textContent = `$${stats.session.avg_cost_per_call.toFixed(4)}`;
    }
    
    const costHourEl = document.getElementById('proj-cost-hour');
    if (costHourEl && stats.rate) {
        costHourEl.textContent = `$${stats.rate.cost_per_hour.toFixed(2)}`;
    }
    
    const remainingHoursEl = document.getElementById('proj-remaining-hours');
    if (remainingHoursEl && stats.projections) {
        const hours = stats.projections.remaining_hours_at_current_rate;
        if (hours === Infinity || hours > 1000) {
            remainingHoursEl.textContent = '∞';
        } else {
            remainingHoursEl.textContent = hours.toFixed(1);
        }
    }
    
    const estimatedTotalEl = document.getElementById('proj-estimated-total');
    if (estimatedTotalEl && stats.projections) {
        estimatedTotalEl.textContent = `$${stats.projections.estimated_total_if_continues.toFixed(2)}`;
    }
}

function updateAlertsDisplay(alerts) {
    const alertsDiv = document.getElementById('cost-alerts');
    if (!alertsDiv) return;
    
    if (!alerts || alerts.length === 0) {
        alertsDiv.innerHTML = `
            <div class="empty-state">
                <i class="fas fa-check-circle"></i>
                <p>No alerts. Budget is healthy.</p>
            </div>
        `;
        return;
    }
    
    // Show most recent alerts (max 5)
    const recentAlerts = alerts.slice(-5).reverse();
    
    alertsDiv.innerHTML = recentAlerts.map(alert => {
        const time = new Date(alert.timestamp).toLocaleTimeString();
        return `
            <div class="cost-alert ${alert.type}">
                <div class="alert-icon">
                    <i class="fas fa-exclamation-triangle"></i>
                </div>
                <div class="alert-content">
                    <div class="alert-message">${alert.message}</div>
                    <div class="alert-time">${time}</div>
                </div>
            </div>
        `;
    }).join('');
}

function startCostAutoRefresh() {
    // Clear any existing interval
    if (costRefreshInterval) {
        clearInterval(costRefreshInterval);
    }
    
    // Refresh every 5 seconds
    costRefreshInterval = setInterval(() => {
        refreshCostData();
    }, 5000);
}

// Manual refresh button
window.refreshCostData = refreshCostData;

// Cleanup on page unload
window.addEventListener('beforeunload', () => {
    if (costRefreshInterval) {
        clearInterval(costRefreshInterval);
    }
});

console.log('💰 Cost tracking module loaded');
