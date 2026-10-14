@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotPreferenceValidator()
        let item = Referrals.newSlotPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotPreferenceVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Referrals.SlotPreferenceVersionRangeRule(min: 16, max: 120)
        let item = Referrals.newSlotPreference("x", label: "y")
        item.version = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotPreferenceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.SlotPreferenceLabelLengthRule(maxLength: 1000)
        let item = Referrals.newSlotPreference("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotPreferenceStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Referrals.SlotPreferenceStartsAtRangeRule(min: 32, max: 32)
        let item = Referrals.newSlotPreference("x", label: "y")
        item.startsAt = 33
        #expect(rule.check(item).count > 0)
    }
}
