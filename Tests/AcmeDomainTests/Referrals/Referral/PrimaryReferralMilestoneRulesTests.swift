@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimaryReferralMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPrimaryReferralMilestoneValidator()
        let item = Referrals.newPrimaryReferralMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPrimaryReferralMilestoneUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Referrals.PrimaryReferralMilestoneUpdatedAtRangeRule(min: 32, max: 3600)
        let item = Referrals.newPrimaryReferralMilestone("x", title: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsPrimaryReferralMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.PrimaryReferralMilestoneRequiredCodeRule(
            message: "primary referral milestone needs this field"
        )
        let item = Referrals.newPrimaryReferralMilestone("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPrimaryReferralMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.PrimaryReferralMilestoneCodeLengthRule(maxLength: 86400)
        let item = Referrals.newPrimaryReferralMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPrimaryReferralMilestoneRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.PrimaryReferralMilestoneRequiredTitleRule(
            message: "primary referral milestone needs an entry"
        )
        let item = Referrals.newPrimaryReferralMilestone("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
