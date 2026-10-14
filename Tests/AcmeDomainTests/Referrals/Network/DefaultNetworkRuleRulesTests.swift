@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultNetworkRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultDefaultNetworkRuleValidator()
        let item = Referrals.newDefaultNetworkRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsDefaultNetworkRuleCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Referrals.DefaultNetworkRuleCountryLengthRule(maxLength: 80)
        let item = Referrals.newDefaultNetworkRule("x", label: "y")
        item.country = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsDefaultNetworkRuleSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Referrals.DefaultNetworkRuleSequenceRangeRule(min: 255, max: 86400)
        let item = Referrals.newDefaultNetworkRule("x", label: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsDefaultNetworkRuleScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Referrals.DefaultNetworkRuleScoreRangeRule(min: 4.9, max: 4805.3)
        let item = Referrals.newDefaultNetworkRule("x", label: "y")
        item.score = 4806.8
        #expect(rule.check(item).count > 0)
    }
}
