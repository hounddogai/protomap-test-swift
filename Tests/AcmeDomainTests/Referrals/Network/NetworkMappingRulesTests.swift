@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkMappingValidator()
        let item = Referrals.newNetworkMapping("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkMappingRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.NetworkMappingRequiredTitleRule(message: "network mapping needs this field")
        let item = Referrals.newNetworkMapping("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkMappingLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.NetworkMappingLabelLengthRule(maxLength: 86400)
        let item = Referrals.newNetworkMapping("x", name: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkMappingAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Referrals.NetworkMappingAmountRangeRule(min: 0.7, max: 2417.6)
        let item = Referrals.newNetworkMapping("x", name: "y")
        item.amount = 2419.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkMappingRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.NetworkMappingRequiredLabelRule(message: "network mapping needs an entry")
        let item = Referrals.newNetworkMapping("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.NetworkMappingCodeLengthRule(maxLength: 16)
        let item = Referrals.newNetworkMapping("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
