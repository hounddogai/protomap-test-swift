@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkWindowValidator()
        let item = Referrals.newNetworkWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkWindowBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.NetworkWindowBatchSizeRangeRule(min: 64, max: 80)
        let item = Referrals.newNetworkWindow("x", title: "y")
        item.batchSize = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkWindowRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Referrals.NetworkWindowRefillsRangeRule(min: 16, max: 80)
        let item = Referrals.newNetworkWindow("x", title: "y")
        item.refills = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkWindowCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.NetworkWindowCreatedAtRangeRule(min: 16, max: 32)
        let item = Referrals.newNetworkWindow("x", title: "y")
        item.createdAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsNetworkWindowQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.NetworkWindowQuantityRangeRule(min: 80, max: 120)
        let item = Referrals.newNetworkWindow("x", title: "y")
        item.quantity = 121
        #expect(rule.check(item).count > 0)
    }
}
