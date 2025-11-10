/**
 * Address entry with postal code lookup
 */

import {LightningElement, api, wire} from 'lwc';
import queryKadaster from '@salesforce/apex/AddressEntryController.queryKadaster';
import No_Results from '@salesforce/label/c.No_Results';

export default class AddressEntry extends LightningElement {
    @api addressRecord;
    postalCode;
    houseNumber;
    houseLetter;
    houseNumberAddition;
    city;
    country = "NL";
    streetName;
    errorMessage;
    connectedCallback() {
        this.convertAddressToFields();
    }

    checkAddress() {
        this.errorMessage = undefined;
        const localThis = this;
        queryKadaster({ postalCode : this.postalCode, houseNumber : this.houseNumber, houseLetter: this.houseLetter, houseNumberAddition: this.houseNumberAddition })
            .then((result) => {
                console.log('### Kadaster result: '+JSON.stringify(result));
                if(result === null) {
                    this.streetName = '';
                    this.city = '';
                    this.resetAddressRecord();
                    this.errorMessage = No_Results;
                } else if(result.status) {
                    //
                    // Error
                    this.errorMessage = result.title;
                    this.streetName = '';
                    this.city = '';
                    this.resetAddressRecord();

                } else {
                    //
                    // Success has no status property set
                    this.createAddressRecord(result);
                    this.convertAddressToFields();
                }
                return;
            })
            .catch((error) => {
                this.errorMessage = error.body.message;
            });
    }
    convertAddressToFields() {
        if(!this.addressRecord) {
            return;
        }
        this.postalCode = this.addressRecord.Postal_Code__c;
        this.streetName = this.addressRecord.Street__c;
        this.city = this.addressRecord.City__c;
        this.country = this.addressRecord.Country__c;
        this.houseNumber = this.addressRecord.House_Number__c;
        this.houseLetter = this.addressRecord.House_Letter__c;
        this.houseNumberAddition = this.addressRecord.House_Number_Addition__c;
    }
    resetAddressRecord() {
        this.addressRecord = undefined;
    }
    createAddressRecord(jsonInput) {

        this.addressRecord = {... this.addressRecord};
        this.addressRecord.Postal_Code__c = jsonInput.postcode;
        this.addressRecord.Street__c = jsonInput.korteNaam;
        this.addressRecord.City__c = jsonInput.woonplaatsNaam;
        this.addressRecord.Country__c = 'NL';
        this.addressRecord.House_Number__c = JSON.stringify(jsonInput.huisnummer);
        this.addressRecord.House_Letter__c = this.houseLetter;
        this.addressRecord.House_Number_Addition__c = this.houseNumberAddition;
        console.log('## Address result '+JSON.stringify(this.addressRecord));
    }


    reloadAddressFromService() {
        if(this.houseNumber && this.postalCode) {
            this.checkAddress();
        }
    }
    doQuery(event) {
        this.reloadAddressFromService();
    }
    handlePostalCodeChange(event) {
        this.postalCode = event.detail.value;

    }
    handleHouseNumberChange(event) {
        this.houseNumber = event.detail.value;
    }
    handleHouseNumberAdditionChange(event) {
        this.houseNumberAddition = event.detail.value;
    }
    handleHouseLetterChange(event) {
        this.houseLetter = event.detail.value;
    }
    handleCityChange(event) {
        this.city = event.detail.value;
    }
    handleCountryChange(event) {
        this.country = event.detail.value;
    }
    handleStreetNameChange(event) {
        this.streetName = event.detail.value;
    }

}