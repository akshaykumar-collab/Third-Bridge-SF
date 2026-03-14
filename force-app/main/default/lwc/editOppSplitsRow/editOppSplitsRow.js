import { LightningElement, api,track,wire } from 'lwc';
export default class EditOppSplitsRow extends LightningElement {

    //Split data
    @api teammemberoptions;
    @api splitteammember;
    @api percent;
    @api amount;
    @api mrrsplit;
    @api tassplit;
    @api split;
    @api index;
    @api id;

    //Opp data
    @api oppamount;
    @api mrrtotal;
    @api tastotal;
    @api recordtype;
    @api type;
    @api showmrr;
    @api showtas;

    @api teamMemberClass = 'normal';

    get showDelete() {
        if(this.index != 0) {
            return true;
        } else {
            return false;
        }
    }

    //Delete Split from array in parent LWC
    deleteSplit() {
        const deleteDetails = {value: this.index};
        const deleteEvent = new CustomEvent('delete', {detail: deleteDetails});
        this.dispatchEvent(deleteEvent); //Tells main LWC that this line needs to be removed from the array
    }

    handleSplitChange() {
        if(this.splitteammember == null || this.splitteammember == '') {
            this.teamMemberClass = 'errorGlow';
        }

        const updateDetails = {value: this.index};
        const updateEvent = new CustomEvent('update', {detail: updateDetails});
        this.dispatchEvent(updateEvent);
    }

    handleTeamMemberSelect(event) {
        this.splitteammember = event.detail.value;
        this.teamMemberClass = 'normal';
    }

    //When MRR changes, recalculate Percent, TAS and Amount
    handleMRRChange(event) {
        this.mrrsplit = event.detail.value;
        
        this.percent = ((this.mrrsplit >= 0) ? (this.mrrsplit / this.mrrtotal) * 100 : 0).toFixed(2);

        const percentField = this.template.querySelectorAll('.percent')[0];
        percentField.value = this.percent;

        this.amount = ((this.percent >= 0) ? this.oppamount * (this.percent / 100) : 0).toFixed(2);

        const amountField = this.template.querySelectorAll('.amount')[0];
        amountField.value = this.amount;
        
        if(this.showtas) {
            this.tassplit = ((this.percent >= 0) ? this.tastotal * (this.percent / 100) : 0).toFixed(0);

            const tasField = this.template.querySelectorAll('.tas')[0];
            tasField.value = this.tassplit;
        }      

        this.handleSplitChange();
    }

    //When Percent changes, recalculate MRR, TAS and Amount
    handlePercentChange(event) {
        this.percent = event.detail.value;

        if(this.showmrr) {
            this.mrrsplit = ((this.percent >= 0) ? this.mrrtotal * (this.percent / 100) : 0).toFixed(2);

            const mrrField = this.template.querySelectorAll('.mrr')[0];
            mrrField.value = this.mrrsplit;
        }

        if(this.showtas) {
            this.tassplit = ((this.percent >= 0) ? this.tastotal * (this.percent / 100) : 0).toFixed(0);

            const tasField = this.template.querySelectorAll('.tas')[0];
            tasField.value = this.tassplit;
        }

        this.amount = ((this.percent >= 0) ? this.oppamount * (this.percent / 100) : 0).toFixed(2);

        const amountField = this.template.querySelectorAll('.amount')[0];
        amountField.value = this.amount;
        
        this.handleSplitChange();
    }

    //When Amount changes, recalculate MRR, TAS and Percent
    handleAmountChange(event) {
        this.amount = event.detail.value;

        this.percent = ((this.amount >= 0) ? (this.amount / this.oppamount) * 100 : 0).toFixed(2);

        const percentField = this.template.querySelectorAll('.percent')[0];
        percentField.value = this.percent;

        if(this.showmrr) {
            this.mrrsplit = ((this.percent >= 0) ? this.mrrtotal * (this.percent / 100) : 0).toFixed(2);

            const mrrField = this.template.querySelectorAll('.mrr')[0];
            mrrField.value = this.mrrsplit;
        }

        if(this.showtas) {
            this.tassplit = ((this.percent >= 0) ? this.tastotal * (this.percent / 100) : 0).toFixed(0);

            const tasField = this.template.querySelectorAll('.tas')[0];
            tasField.value = this.tassplit;
        }

        this.handleSplitChange();
    }

    //When TAS changes, store TAS value
    handleTASChange(event) {
        this.tassplit = event.detail.value;

        this.handleSplitChange();
    }

    @api resetTo100() {
        this.percent = 100;

        const percentField = this.template.querySelectorAll('.percent')[0];
        percentField.value = this.percent;

        if(this.showmrr) {
            this.mrrsplit = ((this.percent >= 0) ? this.mrrtotal * (this.percent / 100) : 0).toFixed(2);

            const mrrField = this.template.querySelectorAll('.mrr')[0];
            mrrField.value = this.mrrsplit;
        }

        if(this.showtas) {
            this.tassplit = ((this.percent >= 0) ? this.tastotal * (this.percent / 100) : 0).toFixed(0);

            const tasField = this.template.querySelectorAll('.tas')[0];
            tasField.value = this.tassplit;
        }

        this.amount = ((this.percent >= 0) ? this.oppamount * (this.percent / 100) : 0).toFixed(2);

        const amountField = this.template.querySelectorAll('.amount')[0];
        amountField.value = this.amount;
        
        this.handleSplitChange();
    }
}