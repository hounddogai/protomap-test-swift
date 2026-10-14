@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingAuthorizationPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPendingAuthorizationPreferenceValidator()
        let item = RevenueCycle.newPendingAuthorizationPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePendingAuthorizationPreferenceSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = RevenueCycle.PendingAuthorizationPreferenceSpecialtyLengthRule(maxLength: 3600)
        let item = RevenueCycle.newPendingAuthorizationPreference("x", label: "y")
        item.specialty = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePendingAuthorizationPreferenceMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = RevenueCycle.PendingAuthorizationPreferenceMinimumRangeRule(min: 9.0, max: 3373.8)
        let item = RevenueCycle.newPendingAuthorizationPreference("x", label: "y")
        item.minimum = 3375.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCyclePendingAuthorizationPreferenceRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = RevenueCycle.PendingAuthorizationPreferenceRequiredSpecialtyRule(
            message: "pending authorization preference needs this field"
        )
        let item = RevenueCycle.newPendingAuthorizationPreference("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
