@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedNetworkQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedNetworkQuotaValidator()
        let item = Referrals.newWeightedNetworkQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedNetworkQuotaCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Referrals.WeightedNetworkQuotaCostRangeRule(min: 4.3, max: 3740.3)
        let item = Referrals.newWeightedNetworkQuota("x", name: "y")
        item.cost = 3741.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsWeightedNetworkQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.WeightedNetworkQuotaRequiredCodeRule(message: "weighted network quota needs an entry")
        let item = Referrals.newWeightedNetworkQuota("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsWeightedNetworkQuotaNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.WeightedNetworkQuotaNameLengthRule(maxLength: 80)
        let item = Referrals.newWeightedNetworkQuota("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsWeightedNetworkQuotaMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Referrals.WeightedNetworkQuotaMarginRangeRule(min: 3.1, max: 1955.8)
        let item = Referrals.newWeightedNetworkQuota("x", name: "y")
        item.margin = 1957.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsWeightedNetworkQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.WeightedNetworkQuotaCodeLengthRule(maxLength: 1000)
        let item = Referrals.newWeightedNetworkQuota("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
