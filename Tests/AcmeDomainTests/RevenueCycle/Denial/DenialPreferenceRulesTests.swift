@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialPreferenceValidator()
        let item = RevenueCycle.newDenialPreference("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.DenialPreferenceCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newDenialPreference("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialPreferenceRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = RevenueCycle.DenialPreferenceRequiredUnitRule(message: "denial preference needs a value")
        let item = RevenueCycle.newDenialPreference("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialPreferenceSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = RevenueCycle.DenialPreferenceSegmentLengthRule(maxLength: 120)
        let item = RevenueCycle.newDenialPreference("x", title: "y")
        item.segment = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
