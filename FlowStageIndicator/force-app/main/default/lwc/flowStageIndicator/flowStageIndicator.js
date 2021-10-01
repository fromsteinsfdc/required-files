import { LightningElement, api } from 'lwc';
const PATH_ITEM_CLASSES = {
    BASE: 'slds-path__item',
    CURRENT: 'slds-is-active',
    COMPLETE: 'slds-is-complete',
    INCOMPLETE: 'slds-is-incomplete'
}

export default class FlowStageIndicator extends LightningElement {
    @api stageListString;
    @api currentStage;
    currentStageIndex;

    get stages() {
        let stages = [];
        if (this.stageListString) {
            for (let stage of this.stageListString.split(',')) {
                stages.push(
                    this.newStage(stage.trim(), stage === this.currentStage)
                );
            }
        }
        this.currentStageIndex = stages.findIndex(stage => stage.isCurrent) || 0;
        for (let i = 0; i < this.currentStageIndex; i++) {
            stages[i].isComplete = true;
        }
        return stages;
    }

    newStage(label, isCurrent) {
        return {
            label: label,
            isCurrent: isCurrent,
            get classString() {
                let classes = [PATH_ITEM_CLASSES.BASE];
                if (this.isCurrent) {
                    classes.push(PATH_ITEM_CLASSES.CURRENT);
                } else if (this.isComplete) {
                    classes.push(PATH_ITEM_CLASSES.COMPLETE);
                } else {
                    classes.push(PATH_ITEM_CLASSES.INCOMPLETE)
                }
                return classes.join(' ');
            }
        }
    }
}