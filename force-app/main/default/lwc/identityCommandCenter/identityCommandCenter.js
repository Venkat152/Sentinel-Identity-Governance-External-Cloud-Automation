import { LightningElement, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import Id from '@salesforce/user/Id';
import getMyTeam from '@salesforce/apex/IdentityGovernanceService.getMyTeam';
import purgeAndBackupUser from '@salesforce/apex/IdentityGovernanceService.purgeAndBackupUser';
import performCredentialReset from '@salesforce/apex/IdentityGovernanceService.performCredentialReset';
import runComplianceBatch from '@salesforce/apex/IdentityGovernanceService.runComplianceBatch';
import checkBatchStatus from '@salesforce/apex/IdentityGovernanceService.checkBatchStatus';
import { refreshApex } from '@salesforce/apex';
import getGoogleDriveFiles from '@salesforce/apex/IdentityGovernanceService.getGoogleDriveFiles';

const ARCHIVE_COLUMNS = [
    { label: 'File Name', fieldName: 'name', type: 'text' },
    { label: 'Date Archived', fieldName: 'createdTime', type: 'date', 
        typeAttributes: { year: "numeric", month: "long", day: "2-digit" } 
    },
    { label: 'View Backup', type: 'button', 
        typeAttributes: { 
            label: 'Open Drive', 
            name: 'open_drive', 
            variant: 'base',
            iconName: 'utility:external_link' 
        } 
    }
];
// const ACTIONS = [
//     { label: 'Reset Password', name: 'Password' },
//     { label: 'Reset MFA', name: 'MFA' },
//     { label: 'Backup & Purge Access', name: 'purge', iconName: 'utility:database' }
// ];

const COLUMNS = [
    { label: 'Name', fieldName: 'Name', type: 'text', sortable: true , hideDefaultActions: true},
    { label: 'Email', fieldName: 'Email', type: 'email', hideDefaultActions: true },
    { label: 'Access Type', fieldName: 'AccessType', type: 'text', hideDefaultActions: true },
    { label: 'Status', fieldName: 'IsActive', type: 'boolean', hideDefaultActions: true },
    {
        label: 'Permission Sets',
        fieldName: 'PsetCount',
        type: 'number',
        cellAttributes: { alignment: 'left' },
        sortable: true, hideDefaultActions: true
    },
    {
        label: 'Remaining Days', 
        fieldName: 'remainingDaysLabel', 
        type: 'text',
        hideDefaultActions: true,
        sortable: true 
    }
];




export default class IdentityCommandCenter extends LightningElement {
    @track teamData;
    @track batchJobId;
    @track batchStatus = 'Not Started';
    @track isLoading = false;
    @track isBatchRunning = false;
    @track isRefreshingArchive = false;
    @track selectedRows = []; // Tracks checkbox selection
    @track archiveData;
    @track searchTeam = '';
    @track pageNumberTeam = 1;
    @track searchArchive = '';
    @track pageNumberArchive = 1;
    
    recordsPerPage = 10;
    archiveColumns = ARCHIVE_COLUMNS;
    
    columns = COLUMNS;
    wiredTeamResult;
    wiredArchivesResult;
    currentUserId = Id;

    sortBy;
sortDirection = 'asc';

handleSort(event) {
    const { fieldName, sortDirection } = event.detail;
    this.sortBy = fieldName;
    this.sortDirection = sortDirection;
    this.sortData(fieldName, sortDirection);
}

sortData(fieldName, direction) {
    let parseData = [...this.teamData];

    let keyValue = (a) => {
        return a[fieldName] ?? '';
    };

    let isReverse = direction === 'asc' ? 1 : -1;

    parseData.sort((x, y) => {
        let a = keyValue(x);
        let b = keyValue(y);

        if (typeof a === 'string') a = a.toLowerCase();
        if (typeof b === 'string') b = b.toLowerCase();

        return isReverse * ((a > b) - (b > a));
    });

    this.teamData = parseData;
}


@wire(getMyTeam)
wiredTeam(result) {
    this.wiredTeamResult = result;
    if (result.data) {
        console.log('Raw team data:', JSON.stringify(result.data, null, 2));
        this.teamData = result.data.map(row => ({ 
            ...row, 
            actions: this.getRowActions(row),
            remainingDaysLabel: this.formatRemainingDays(row.EndDate)  // Format here
        }));
        console.log('First row formatted:', this.teamData[0]);
        this.pageNumberTeam = 1;
    }
}

// New method to format remaining days
formatRemainingDays(endDate) {
    if (!endDate) return 'No Date';
    
    const today = new Date();
    today.setHours(0, 0, 0, 0); // Normalize to start of day
    
    const end = new Date(endDate);
    end.setHours(0, 0, 0, 0);
    
    const diffTime = end.getTime() - today.getTime();
    const diffDays = Math.floor(diffTime / (1000 * 60 * 60 * 24));
    
    if (diffDays === 0) {
        return 'Today';
    } else if (diffDays > 0) {
        return `${diffDays} Day${diffDays > 1 ? 's' : ''} to go`;
    } else {
        return `Expired ${Math.abs(diffDays)} Day${Math.abs(diffDays) > 1 ? 's' : ''} ago`;
    }
}

    // Logic to disable buttons if nothing is selected
    get isNoRowsSelected() {
        return this.selectedRows.length === 0;
    }

    // Disable Deactivate if no rows selected or no active users in selection
    get isDeactivateDisabled() {
        return this.selectedRows.length === 0 || !this.selectedRows.some(row => row.IsActive);
    }

    // Disable credential resets (Password/MFA) if no rows selected or no active users in selection
    get isCredentialResetDisabled() {
        return this.selectedRows.length === 0 || !this.selectedRows.some(row => row.IsActive);
    }

    // Disable purge only if no rows selected or if all selected users have 0 permission sets
    get isPurgeDisabled() {
        return this.selectedRows.length === 0 || !this.selectedRows.some(row => row.PsetCount > 0);
    }

    // TEAM TABLE PAGINATION & SEARCH
    get filteredTeamData() {
        if (!this.teamData) return [];
        if (!this.searchTeam) return this.teamData;
        
        const searchLower = this.searchTeam.toLowerCase();
        return this.teamData.filter(user => 
            user.Name.toLowerCase().includes(searchLower) ||
            user.Email.toLowerCase().includes(searchLower)
        );
    }

    get totalTeamPages() {
        return Math.ceil(this.filteredTeamData.length / this.recordsPerPage) || 1;
    }

    get paginatedTeamData() {
        const start = (this.pageNumberTeam - 1) * this.recordsPerPage;
        return this.filteredTeamData.slice(start, start + this.recordsPerPage);
    }

    get teamPaginationInfo() {
        const total = this.filteredTeamData.length;
        const start = total === 0 ? 0 : (this.pageNumberTeam - 1) * this.recordsPerPage + 1;
        const end = Math.min(this.pageNumberTeam * this.recordsPerPage, total);
        return `Showing ${start}-${end} of ${total} users`;
    }

    get isTeamFirstPage() {
        return this.pageNumberTeam === 1;
    }

    get isTeamLastPage() {
        return this.pageNumberTeam >= this.totalTeamPages;
    }

    handleTeamSearch(event) {
        this.searchTeam = event.target.value;
        this.pageNumberTeam = 1; // Reset to first page on search
    }

    handleTeamPreviousPage() {
        if (this.pageNumberTeam > 1) {
            this.pageNumberTeam -= 1;
        }
    }

    handleTeamNextPage() {
        if (this.pageNumberTeam < this.totalTeamPages) {
            this.pageNumberTeam += 1;
        }
    }

    // ARCHIVE TABLE PAGINATION & SEARCH
    get filteredArchiveData() {
        if (!this.archiveData) return [];
        if (!this.searchArchive) return this.archiveData;
        
        const searchLower = this.searchArchive.toLowerCase();
        return this.archiveData.filter(file => 
            file.name.toLowerCase().includes(searchLower)
        );
    }

    get totalArchivePages() {
        return Math.ceil(this.filteredArchiveData.length / this.recordsPerPage) || 1;
    }

    get paginatedArchiveData() {
        const start = (this.pageNumberArchive - 1) * this.recordsPerPage;
        return this.filteredArchiveData.slice(start, start + this.recordsPerPage);
    }

    get archivePaginationInfo() {
        const total = this.filteredArchiveData.length;
        const start = total === 0 ? 0 : (this.pageNumberArchive - 1) * this.recordsPerPage + 1;
        const end = Math.min(this.pageNumberArchive * this.recordsPerPage, total);
        return `Showing ${start}-${end} of ${total} backups`;
    }

    get isArchiveFirstPage() {
        return this.pageNumberArchive === 1;
    }

    get isArchiveLastPage() {
        return this.pageNumberArchive >= this.totalArchivePages;
    }

    handleArchiveSearch(event) {
        this.searchArchive = event.target.value;
        this.pageNumberArchive = 1; // Reset to first page on search
    }

    handleArchivePreviousPage() {
        if (this.pageNumberArchive > 1) {
            this.pageNumberArchive -= 1;
        }
    }

    handleArchiveNextPage() {
        if (this.pageNumberArchive < this.totalArchivePages) {
            this.pageNumberArchive += 1;
        }
    }

    // Get conditional row actions based on user status
    getRowActions(row) {
        let actions = [];
        if (row.IsActive) {
            actions.push({ label: 'Reset Password', name: 'Password' });
            actions.push({ label: 'Reset MFA', name: 'MFA' });
        }
        actions.push({ label: 'Backup & Purge Access', name: 'purge', iconName: 'utility:database' });
        return actions;
    }

    // Updates the list of selected rows whenever checkboxes change
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    // --- BULK ACTION HANDLERS ---

    async handleBulkPassword() {
        const userIds = this.selectedRows.map(row => row.Id);
        await this.processBulkCredential(userIds, 'Password');
    }

    async handleBulkMFA() {
        const userIds = this.selectedRows.map(row => row.Id);
        await this.processBulkCredential(userIds, 'MFA');
    }

    async handleBulkPurge() {
        this.isLoading = true;
        try {
            const userIds = this.selectedRows.map(row => row.Id);

            await purgeAndBackupUser({ userIds : userIds });

            this.showToast('Success', 'Backup and Purge completed for selected users.', 'success');
            await refreshApex(this.wiredTeamResult);
        } catch (error) {
            const message =
                error?.body?.message ||
                error?.message ||
                'Unknown error occurred';
            this.showToast('Error', message, 'error');
        } finally {
            this.isLoading = false;
        }
    }


    // Helper for Credential Resets (Handles multiple IDs in one Apex call)
    async processBulkCredential(userIds, type) {
        this.isLoading = true;
        try {
            await performCredentialReset({ userIds: userIds, resetType: type });
            this.showToast('Success', `Bulk ${type} reset initiated for ${userIds.length} users.`, 'success');
            return refreshApex(this.wiredTeamResult);
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }


    // --- BATCH METHODS ---

    async handleStartBatch() {
        this.isLoading = true;
        try {
            this.batchJobId = await runComplianceBatch();
            this.isBatchRunning = true;
            this.showToast('Batch Started', 'Identity Compliance job is now in the queue.', 'info');
            this.getBatchStatus();
        } catch (error) {
            this.showToast('Batch Error', error.body.message, 'warning');
        } finally {
            this.isLoading = false;
        }
    }

    async getBatchStatus() {
        if (!this.batchJobId) return;
        try {
            this.batchStatus = await checkBatchStatus({ jobId: this.batchJobId });
            if (this.batchStatus.includes('Completed')) {
                this.isBatchRunning = false;
                refreshApex(this.wiredTeamResult);
            }
        } catch (error) {
            console.error('Status Error', error);
        }
    }

    showToast(title, message, variant) {
        this.dispatchEvent(new ShowToastEvent({ title, message, variant }));
    }

    // --- NEW BULK DEACTIVATE HANDLER ---
    async handleBulkDeactivate() {
        const userIds = this.selectedRows.map(row => row.Id);
        
        // Safety check to prevent deactivating yourself
        if (userIds.includes(this.currentUserId)) {
            this.showToast('Warning', 'You cannot deactivate your own account.', 'warning');
            return;
        }

        this.isLoading = true;
        try {
            await performCredentialReset({ userIds: userIds, resetType: 'Deactivate' });
            this.showToast('Success', `${userIds.length} users have been deactivated.`, 'success');
            return refreshApex(this.wiredTeamResult);
        } catch (error) {
            this.showToast('Error', error.body.message, 'error');
        } finally {
            this.isLoading = false;
        }
    }

    @wire(getGoogleDriveFiles)
    wiredArchives(result) {
        this.wiredArchivesResult = result;
        if (result.data) {
            this.archiveData = result.data;
            console.log('Archived Files:', this.archiveData);
        } else if (result.error) {
            console.error('Error fetching archived files:', result.error);
            this.showToast('Archive Error', 'Unable to load backup files: ' + result.error.body.message, 'error');
        }
    }

    async refreshArchiveData() {
        this.isRefreshingArchive = true;
        try {
            await refreshApex(this.wiredArchivesResult);
            this.showToast('Success', 'Archive vault refreshed successfully.', 'success');
        } catch (error) {
            this.showToast('Error', 'Failed to refresh archive data.', 'error');
        } finally {
            this.isRefreshingArchive = false;
        }
    }

    get hasNoArchiveData(){
        return !this.filteredArchiveData || this.filteredArchiveData.length === 0;
    }

    handleArchiveRowAction(event) {
        const row = event.detail.row;
        // Opens the Google Drive link in a new tab
        window.open(row.webViewLink, '_blank');
    }
}