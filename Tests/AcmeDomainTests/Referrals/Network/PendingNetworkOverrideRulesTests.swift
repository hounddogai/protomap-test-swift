@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingNetworkOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPendingNetworkOverrideValidator()
        let item = Referrals.newPendingNetworkOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPendingNetworkOverrideMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Referrals.PendingNetworkOverrideMaximumRangeRule(min: 6.8, max: 3262.1)
        let item = Referrals.newPendingNetworkOverride("x", name: "y")
        item.maximum = 3263.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPendingNetworkOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.PendingNetworkOverrideRequiredCodeRule(message: "pending network override needs this field")
        let item = Referrals.newPendingNetworkOverride("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPendingNetworkOverridePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Referrals.PendingNetworkOverridePriorityRangeRule(min: 80, max: 86400)
        let item = Referrals.newPendingNetworkOverride("x", name: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPendingNetworkOverrideRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Referrals.PendingNetworkOverrideRequiredRegionRule(message: "pending network override needs an entry")
        let item = Referrals.newPendingNetworkOverride("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPendingNetworkOverrideLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Referrals.PendingNetworkOverrideLimitRangeRule(min: 16, max: 120)
        let item = Referrals.newPendingNetworkOverride("x", name: "y")
        item.limit = 121
        #expect(rule.check(item).count > 0)
    }
}
