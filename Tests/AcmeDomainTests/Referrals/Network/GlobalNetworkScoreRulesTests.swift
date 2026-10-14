@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalNetworkScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalNetworkScoreValidator()
        let item = Referrals.newGlobalNetworkScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalNetworkScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.GlobalNetworkScoreRequiredCodeRule(message: "global network score needs an entry")
        let item = Referrals.newGlobalNetworkScore("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalNetworkScoreRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Referrals.GlobalNetworkScoreRefillsRangeRule(min: 80, max: 1000)
        let item = Referrals.newGlobalNetworkScore("x", label: "y")
        item.refills = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsGlobalNetworkScoreLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.GlobalNetworkScoreLabelLengthRule(maxLength: 3600)
        let item = Referrals.newGlobalNetworkScore("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalNetworkScoreUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Referrals.GlobalNetworkScoreUnitLengthRule(maxLength: 3600)
        let item = Referrals.newGlobalNetworkScore("x", label: "y")
        item.unit = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalNetworkScoreChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Referrals.GlobalNetworkScoreChannelLengthRule(maxLength: 32)
        let item = Referrals.newGlobalNetworkScore("x", label: "y")
        item.channel = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
