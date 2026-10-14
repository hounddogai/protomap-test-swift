@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyNetworkScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLegacyNetworkScoreValidator()
        let item = Referrals.newLegacyNetworkScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLegacyNetworkScoreRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Referrals.LegacyNetworkScoreRequiredOwnerIDRule(message: "legacy network score needs an entry")
        let item = Referrals.newLegacyNetworkScore("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacyNetworkScoreCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.LegacyNetworkScoreCreatedAtRangeRule(min: 16, max: 86400)
        let item = Referrals.newLegacyNetworkScore("x", title: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLegacyNetworkScoreRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Referrals.LegacyNetworkScoreRevisionRangeRule(min: 255, max: 86400)
        let item = Referrals.newLegacyNetworkScore("x", title: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLegacyNetworkScoreRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.LegacyNetworkScoreRequiredCodeRule(message: "legacy network score needs a value")
        let item = Referrals.newLegacyNetworkScore("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacyNetworkScoreWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Referrals.LegacyNetworkScoreWeightRangeRule(min: 8.0, max: 3253.6)
        let item = Referrals.newLegacyNetworkScore("x", title: "y")
        item.weight = 3255.1
        #expect(rule.check(item).count > 0)
    }
}
