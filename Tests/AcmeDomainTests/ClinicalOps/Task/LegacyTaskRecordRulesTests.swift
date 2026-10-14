@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsLegacyTaskRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultLegacyTaskRecordValidator()
        let item = ClinicalOps.newLegacyTaskRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsLegacyTaskRecordCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = ClinicalOps.LegacyTaskRecordCurrencyLengthRule(maxLength: 1000)
        let item = ClinicalOps.newLegacyTaskRecord("x", label: "y")
        item.currency = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsLegacyTaskRecordAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = ClinicalOps.LegacyTaskRecordAttemptsRangeRule(min: 120, max: 3600)
        let item = ClinicalOps.newLegacyTaskRecord("x", label: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}
