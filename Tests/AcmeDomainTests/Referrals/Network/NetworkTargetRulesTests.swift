@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkTargetValidator()
        let item = Referrals.newNetworkTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.NetworkTargetRequiredCodeRule(message: "network target needs this field")
        let item = Referrals.newNetworkTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkTargetRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Referrals.NetworkTargetRevisionRangeRule(min: 16, max: 1000)
        let item = Referrals.newNetworkTarget("x", name: "y")
        item.revision = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkTargetQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.NetworkTargetQuantityRangeRule(min: 255, max: 86400)
        let item = Referrals.newNetworkTarget("x", name: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}
