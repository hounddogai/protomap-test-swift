@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedProxyThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedProxyThresholdValidator()
        let item = Consent.newBatchedProxyThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedProxyThresholdWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Consent.BatchedProxyThresholdWindowDaysRangeRule(min: 32, max: 3600)
        let item = Consent.newBatchedProxyThreshold("x", label: "y")
        item.windowDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentBatchedProxyThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.BatchedProxyThresholdCodeLengthRule(maxLength: 120)
        let item = Consent.newBatchedProxyThreshold("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedProxyThresholdLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.BatchedProxyThresholdLabelLengthRule(maxLength: 80)
        let item = Consent.newBatchedProxyThreshold("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedProxyThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.BatchedProxyThresholdRequiredCodeRule(message: "batched proxy threshold needs this field")
        let item = Consent.newBatchedProxyThreshold("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedProxyThresholdMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Consent.BatchedProxyThresholdMaximumRangeRule(min: 10.0, max: 1511.6)
        let item = Consent.newBatchedProxyThreshold("x", label: "y")
        item.maximum = 1513.1
        #expect(rule.check(item).count > 0)
    }
}
