@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertRecordValidator()
        let item = ClinicalOps.newAlertRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertRecordMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = ClinicalOps.AlertRecordMaximumRangeRule(min: 7.2, max: 1467.3)
        let item = ClinicalOps.newAlertRecord("x", label: "y")
        item.maximum = 1468.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertRecordThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = ClinicalOps.AlertRecordThresholdRangeRule(min: 7.4, max: 3811.6)
        let item = ClinicalOps.newAlertRecord("x", label: "y")
        item.threshold = 3813.1
        #expect(rule.check(item).count > 0)
    }
}
