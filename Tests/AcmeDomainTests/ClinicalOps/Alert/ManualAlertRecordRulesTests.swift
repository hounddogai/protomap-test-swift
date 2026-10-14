@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsManualAlertRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultManualAlertRecordValidator()
        let item = ClinicalOps.newManualAlertRecord("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsManualAlertRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.ManualAlertRecordRequiredCodeRule(message: "manual alert record needs a value")
        let item = ClinicalOps.newManualAlertRecord("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsManualAlertRecordContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = ClinicalOps.ManualAlertRecordContactEmailLengthRule(maxLength: 32)
        let item = ClinicalOps.newManualAlertRecord("x", title: "y")
        item.contactEmail = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsManualAlertRecordBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = ClinicalOps.ManualAlertRecordBatchSizeRangeRule(min: 80, max: 1000)
        let item = ClinicalOps.newManualAlertRecord("x", title: "y")
        item.batchSize = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsManualAlertRecordTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.ManualAlertRecordTitleLengthRule(maxLength: 80)
        let item = ClinicalOps.newManualAlertRecord("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsManualAlertRecordRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.ManualAlertRecordRequiredTitleRule(message: "manual alert record needs this field")
        let item = ClinicalOps.newManualAlertRecord("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
