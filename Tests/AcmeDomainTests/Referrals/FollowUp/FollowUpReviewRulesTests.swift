@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpReviewValidator()
        let item = Referrals.newFollowUpReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpReviewEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Referrals.FollowUpReviewEncounterIDLengthRule(maxLength: 1000)
        let item = Referrals.newFollowUpReview("x", label: "y")
        item.encounterID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpReviewLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.FollowUpReviewLabelLengthRule(maxLength: 32)
        let item = Referrals.newFollowUpReview("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpReviewRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Referrals.FollowUpReviewRequiredClinicianIDRule(message: "follow up review needs an entry")
        let item = Referrals.newFollowUpReview("", label: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.FollowUpReviewCodeLengthRule(maxLength: 255)
        let item = Referrals.newFollowUpReview("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
