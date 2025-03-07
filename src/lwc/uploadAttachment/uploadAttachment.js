import { LightningElement } from 'lwc';
 
export default class UploadAttachment extends LightningElement {
    fileData;

    handleFileChange(event) {
        const file = event.target.files[0];
        if (file) {
            const reader = new FileReader();
            reader.onload = () => {
                this.fileData = {
                    filename: file.name,
                    base64: reader.result.split(',')[1]
                };
            };
            reader.readAsDataURL(file);
        }
    }

    handleUpload() {
        if (this.fileData) {
            alert('Uploading...')
        }
    }
}