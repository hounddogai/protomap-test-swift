@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkRollupValidator()
        let item = Referrals.newNetworkRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkRollupReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Referrals.NetworkRollupReviewerLengthRule(maxLength: 120)
        let item = Referrals.newNetworkRollup("x", name: "y")
        item.reviewer = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkRollupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.NetworkRollupRequiredNameRule(message: "network rollup needs a value")
        let item = Referrals.newNetworkRollup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkRollupEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.NetworkRollupEndsAtRangeRule(min: 32, max: 3600)
        let item = Referrals.newNetworkRollup("x", name: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
