import { LightningElement, api,track,wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { CloseActionScreenEvent } from 'lightning/actions';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';

import getSplits from '@salesforce/apex/editOppSplitsController.getSplits';
import getOppTeam from '@salesforce/apex/editOppSplitsController.getOppTeam';
import getOpp from '@salesforce/apex/editOppSplitsController.getOpp';
import saveSplits from '@salesforce/apex/editOppSplitsController.saveSplits';

export default class EditOppSplits extends LightningElement {

    @api recordId;

    @track splits = [];
    @track originalSplits = []; //Used to revert Splits list in the event of a change discard
    @track opp;
    @track tas;
    @track splitsToDelete = [];
    @track teamMembersWire = [];
    @track oppWire = [];
    @track splitWire = [];

    @track totalPercent = 100;
    @track totalAmount;
    @track totalMRR;
    @track totalTAS;

    renderSplits = true; //Used to re-render Splits list when discarding changes
    @track loading = false;

    disableSave = false;
    showPercentError = false;
    showTASError = false;
    showMRRError = false;
    duplicateError = false;

    teamMemberOptions = [
        {label: '', value: ''} //Stores team member options from APEX query
    ];

    renderedCallback() {
        refreshApex(this.teamMembersWire);
        refreshApex(this.oppWire);
        refreshApex(this.splitWire);
    }

    get showMRR() {
        if(this.opp) {
            if(this.opp.RecordType.Name.includes("Forum") || this.opp.RecordType.Name.includes("FM")) {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    get showTAS() {
        if(this.opp) {
            if((this.opp.RecordType.Name.includes("Connections") || this.opp.RecordType.Name.includes("CX")) && this.opp.Type == 'New Business') {
                return true;
            } else {
                return false;
            }
        } else {
            return true;
        }
    }

    get tasErrorMessage() {
        if(this.opp) {
            return 'Total TAS must add up to Original Global TAS of ' + this.tas;
        } else {
            return '';
        }
    }

    get mrrErrorMessage() {
        if(this.opp) {
            return 'Total MRR must add up to the total MRR of the Opp. You are missing $' + (this.opp.Forum_MRR_2__c - this.totalMRR).toFixed(2);
        } else {
            return '';
        }
    }

    @wire(getOpp, {oppId: '$recordId'})
    oppData(result){
        this.oppWire = result;

        if(result.data) {
            this.opp = result.data;
            this.totalAmount = this.opp.Amount;
            this.totalMRR = this.opp.Forum_MRR_2__c;
            this.tas = ((this.opp.Global_ENTERPRISE_TAS_ORIGINAL__c > 0) ? this.opp.Global_ENTERPRISE_TAS_ORIGINAL__c : this.opp.Global_ACCESSIBLE_TAS_ORIGINAL__c);
            this.totalTAS = this.tas;

            this.tas = ((this.opp.Global_ENTERPRISE_TAS_ORIGINAL__c > 0) ? this.opp.Global_ENTERPRISE_TAS_ORIGINAL__c : this.opp.Global_ACCESSIBLE_TAS_ORIGINAL__c);
        
            this.initialSetTotalClass();
        } else if(result.error) {
            console.log('getOpp Error: ' + JSON.stringify(result.error));
        } else {
            console.log('Unknown getOpp error');
        }
    }

    @wire(getSplits, {oppId: '$recordId'})
    splitData(result){
        this.splitWire = result;

        if(result.data) {
            this.splits = [...result.data];
            this.originalSplits = [...result.data];

            this.initialSetTotalClass();
        } else if(result.error) {
            console.log('getSplits Error: ' + JSON.stringify(result.error));
        } else {
            console.log('Unknown getSplits error');
        }
    }

    @wire(getOppTeam, {oppId: '$recordId'})
    teamData(result){
        this.teamMembersWire = result;

        if(result.data) {
            //Reset options to blank
            this.teamMemberOptions = [
                {label: '', value: ''} 
            ];
            for(let i = 0; i < this.teamMembersWire.data.length; i++) {
                this.teamMemberOptions = [...this.teamMemberOptions, {label: this.teamMembersWire.data[i].User.Name, value: this.teamMembersWire.data[i].UserId}];
            }
        } else if(result.error) {
            console.log('getOppTeam Error: ' + JSON.stringify(result.error));
        } else {
            console.log('Unknown getOppTeam error');
        }
    }

    //Checks to see if splits list has any duplicates
    duplicateCheck() {
        let teamMembersStrings = this.splits.map(function(item) {
            return item.SplitOwnerId;
        });
        let test = (new Set(teamMembersStrings)).size !== teamMembersStrings.length;
        return test;
    }

    //Adds blank row to the screen
    addRow() {
        let blankRow = {
            Id: '',
            SplitAmount: null,
            SplitPercentage: null,
            SplitOwnerId: '',
            MRR_Split__c: null,
            TAS_Split__c: null
        }
        this.splits = [...this.splits, blankRow];

        setTimeout(()=>{
            this.updateSplitTotals();
        }, 0.1);
    }

    //Reset Split array and update front end field values on component by component level
    discardChanges() {
        this.splits = [...this.originalSplits];
        this.splitsToDelete = [];
        this.totalPercent = 100;
        this.totalAmount = this.opp.Amount;
        this.totalMRR = this.opp.Forum_MRR_2__c;
        this.totalTAS = this.opp.Global_ENTERPRISE_TAS_ORIGINAL__c;

        this.dispatchEvent(new CloseActionScreenEvent());
    }

    //Save splits to Salesforce
    async saveChanges() {
        this.updateSplitArr();

        if(this.duplicateCheck()) {
            this.loading = false;

            const evt = new ShowToastEvent({
                title: 'Error',
                message: 'There is a duplicate split. Each team member can only have one split on the Opportunity.',
                variant: 'error',
            });
            this.dispatchEvent(evt);

            return;
        }

        saveSplits({splitsToDelete: JSON.stringify(this.splitsToDelete), splits: JSON.stringify(this.splits), oppId: this.recordId})
            .then(result => {
                this.loading = false;
                this.dispatchEvent(new CloseActionScreenEvent());
                const evt = new ShowToastEvent({
                    title: 'Success!',
                    message: 'The Opportunity Splits for this Opp have been updated',
                    variant: 'success',
                });
                this.dispatchEvent(evt);
            })
            .catch(error => {
                let errorMsg = "";
                this.loading = false;
                console.log(JSON.stringify(error));
                if(error.body.message) {
                    errorMsg = error.body.message;
                } else {
                    errorMsg = error.body.pageErrors[0].message;
                }
                const evt = new ShowToastEvent({
                    title: 'Error',
                    message: 'Please provide the following error message to Salesforce support: ' + errorMsg,
                    variant: 'error',
                });
                this.dispatchEvent(evt);
            });

        
    }

    //Deletes split
    deleteSplit(event) {
        let temp = this.splits.splice(event.detail.value, 1)[0];

        if(temp.Id != null && temp.Id != '') {
            this.splitsToDelete.push(temp);
        }

        setTimeout(()=>{
            this.updateSplitTotals();

            const allSplits = this.template.querySelectorAll('c-edit-opp-splits-row');
            if(allSplits.length == 1) {
                allSplits[0].resetTo100();
            }
        }, 0.1);
    }

    //Recalculate Total Amount and Total Percent on split change
    updateSplitTotals() {
        this.totalAmount = 0;
        this.totalPercent = 0;
        this.totalMRR = 0;
        this.totalTAS = 0;

        const allSplits = this.template.querySelectorAll('c-edit-opp-splits-row');
        for(let i = 0; i < allSplits.length; i++) {
            if(allSplits[i].amount >= 0 && allSplits[i].amount != null) {
                this.totalAmount +=parseFloat(allSplits[i].amount);
            }
            if(allSplits[i].percent >= 0 && allSplits[i].percent != null) {
                this.totalPercent += parseFloat(allSplits[i].percent);
            }
            if(allSplits[i].mrrsplit >= 0 && allSplits[i].mrrsplit != null) {
                this.totalMRR += parseFloat(allSplits[i].mrrsplit);
            }
            if(allSplits[i].tassplit >= 0 && allSplits[i].tassplit != null) {
                this.totalTAS += parseFloat(allSplits[i].tassplit);
            }
        }

        this.totalPercent = Math.round((this.totalPercent + Number.EPSILON) * 100) / 100;
        this.setTotalClass();
    }

    initialSetTotalClass() {
        if(this.opp && this.splits) {
            this.setTotalClass();
        }
    }

    //Determine class to use for Total Percent class
    setTotalClass() {
        this.disableSave = false;

        if(this.totalPercent != 100) {
            this.showPercentError = true;
            this.disableSave = true;
        } else {
            this.showPercentError = false;

        }

        if(this.showTAS) {
            if(this.totalTAS != this.tas) {
                this.showTASError = true;
                this.disableSave = true;
            } else {
                this.showTASError = false;
            }
        }

        if(this.showMRR) {
            if((this.opp.Forum_MRR_2__c.toFixed(2)) != (this.totalMRR.toFixed(2))) {
                this.showMRRError = true;
                this.disableSave = true;
            } else {
                this.showMRRError = false;
            }
        }

        const allSplits = this.template.querySelectorAll('c-edit-opp-splits-row');
        for(let i = 0; i < allSplits.length; i++) {
            if(allSplits[i].splitteammember == null || allSplits[i].splitteammember == '') {
                this.disableSave = true;
            }
        }  
    }

    updateSplitArr() {
        this.loading = true;
        const allSplits = this.template.querySelectorAll('c-edit-opp-splits-row');
        let newSplits = [];
        for(let i = 0; i < allSplits.length; i++) {
            let split = {
                Id: ((allSplits[i].id != null && allSplits[i].id != '') ? allSplits[i].id.substring(0,18) : null),
                SplitPercentage: ((allSplits[i].percent > 0) ? allSplits[i].percent : 0),
                SplitAmount: ((allSplits[i].amount > 0) ? allSplits[i].amount : 0),
                SplitOwnerId: allSplits[i].splitteammember,
                MRR_Split__c: allSplits[i].mrrsplit,
                TAS_Split__c: allSplits[i].tassplit,
                OpportunityId: this.recordId
            }
            newSplits.push(split);
        }
        this.splits = [...newSplits];
    }

}