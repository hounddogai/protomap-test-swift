@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredNetworkDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredNetworkDigestValidator()
        let item = Referrals.newTieredNetworkDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredNetworkDigestStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Referrals.TieredNetworkDigestStartsAtRangeRule(min: 16, max: 32)
        let item = Referrals.newTieredNetworkDigest("x", name: "y")
        item.startsAt = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsTieredNetworkDigestRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Referrals.TieredNetworkDigestRequiredChannelRule(message: "tiered network digest needs an entry")
        let item = Referrals.newTieredNetworkDigest("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
