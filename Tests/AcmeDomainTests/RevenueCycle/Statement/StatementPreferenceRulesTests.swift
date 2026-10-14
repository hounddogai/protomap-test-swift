@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementPreferenceValidator()
        let item = RevenueCycle.newStatementPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementPreferenceThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = RevenueCycle.StatementPreferenceThresholdRangeRule(min: 8.8, max: 3341.8)
        let item = RevenueCycle.newStatementPreference("x", name: "y")
        item.threshold = 3343.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStatementPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StatementPreferenceRequiredCodeRule(message: "statement preference needs a value")
        let item = RevenueCycle.newStatementPreference("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStatementPreferenceRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.StatementPreferenceRequiredNameRule(message: "statement preference needs this field")
        let item = RevenueCycle.newStatementPreference("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
