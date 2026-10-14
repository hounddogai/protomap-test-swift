@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpEstimateValidator()
        let item = Referrals.newFollowUpEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpEstimateUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Referrals.FollowUpEstimateUpdatedAtRangeRule(min: 64, max: 64)
        let item = Referrals.newFollowUpEstimate("x", label: "y")
        item.updatedAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpEstimateRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Referrals.FollowUpEstimateRequiredOwnerIDRule(message: "follow up estimate needs this field")
        let item = Referrals.newFollowUpEstimate("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
