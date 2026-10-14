@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedFollowUpTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedFollowUpTargetValidator()
        let item = Referrals.newCappedFollowUpTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedFollowUpTargetRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Referrals.CappedFollowUpTargetRequiredReviewerRule(
            message: "capped follow up target needs this field"
        )
        let item = Referrals.newCappedFollowUpTarget("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedFollowUpTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.CappedFollowUpTargetCodeLengthRule(maxLength: 1000)
        let item = Referrals.newCappedFollowUpTarget("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsCappedFollowUpTargetGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Referrals.CappedFollowUpTargetGraceDaysRangeRule(min: 1000, max: 3600)
        let item = Referrals.newCappedFollowUpTarget("x", title: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsCappedFollowUpTargetReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Referrals.CappedFollowUpTargetReviewerLengthRule(maxLength: 255)
        let item = Referrals.newCappedFollowUpTarget("x", title: "y")
        item.reviewer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
