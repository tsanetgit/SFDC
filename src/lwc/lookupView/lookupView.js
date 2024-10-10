import { LightningElement, api } from 'lwc';
 
export default class LookupView extends LightningElement {
    @api iconName
    @api value
    @api label
}