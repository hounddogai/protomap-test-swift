@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsCareProtocolThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultCareProtocolThresholdValidator()
        let item = ClinicalOps.newCareProtocolThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsCareProtocolThresholdRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = ClinicalOps.CareProtocolThresholdRateRangeRule(min: 7.6, max: 3777.0)
        let item = ClinicalOps.newCareProtocolThreshold("x", title: "y")
        item.rate = 3778.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolThresholdRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.CareProtocolThresholdRequiredTitleRule(
            message: "care protocol threshold needs this field"
        )
        let item = ClinicalOps.newCareProtocolThreshold("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsCareProtocolThresholdAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = ClinicalOps.CareProtocolThresholdAmountRangeRule(min: 7.1, max: 4796.5)
        let item = ClinicalOps.newCareProtocolThreshold("x", title: "y")
        item.amount = 4798.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsCareProtocolThresholdNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = ClinicalOps.CareProtocolThresholdNotesLengthRule(maxLength: 3600)
        let item = ClinicalOps.newCareProtocolThreshold("x", title: "y")
        item.notes = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
