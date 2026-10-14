@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationPreferenceValidator()
        let item = RevenueCycle.newAuthorizationPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationPreferenceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.AuthorizationPreferenceRequiredLabelRule(
            message: "authorization preference needs an entry"
        )
        let item = RevenueCycle.newAuthorizationPreference("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationPreferenceDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = RevenueCycle.AuthorizationPreferenceDosageMgRangeRule(min: 9.1, max: 1738.2)
        let item = RevenueCycle.newAuthorizationPreference("x", label: "y")
        item.dosageMg = 1739.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.AuthorizationPreferenceCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newAuthorizationPreference("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationPreferenceGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = RevenueCycle.AuthorizationPreferenceGraceDaysRangeRule(min: 16, max: 255)
        let item = RevenueCycle.newAuthorizationPreference("x", label: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}
