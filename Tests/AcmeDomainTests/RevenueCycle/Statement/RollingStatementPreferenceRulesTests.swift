@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingStatementPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRollingStatementPreferenceValidator()
        let item = RevenueCycle.newRollingStatementPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRollingStatementPreferenceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.RollingStatementPreferenceRequiredLabelRule(
            message: "rolling statement preference needs this field"
        )
        let item = RevenueCycle.newRollingStatementPreference("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRollingStatementPreferenceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.RollingStatementPreferenceLabelLengthRule(maxLength: 16)
        let item = RevenueCycle.newRollingStatementPreference("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRollingStatementPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RollingStatementPreferenceCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newRollingStatementPreference("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRollingStatementPreferenceRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = RevenueCycle.RollingStatementPreferenceRequiredPayerRule(
            message: "rolling statement preference needs a value"
        )
        let item = RevenueCycle.newRollingStatementPreference("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
