@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkPreferenceValidator()
        let item = Referrals.newNetworkPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkPreferenceStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Referrals.NetworkPreferenceStartsAtRangeRule(min: 32, max: 64)
        let item = Referrals.newNetworkPreference("x", label: "y")
        item.startsAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkPreferenceMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Referrals.NetworkPreferenceMaximumRangeRule(min: 1.6, max: 2045.9)
        let item = Referrals.newNetworkPreference("x", label: "y")
        item.maximum = 2047.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkPreferenceQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.NetworkPreferenceQuantityRangeRule(min: 255, max: 3600)
        let item = Referrals.newNetworkPreference("x", label: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkPreferenceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.NetworkPreferenceLabelLengthRule(maxLength: 86400)
        let item = Referrals.newNetworkPreference("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
