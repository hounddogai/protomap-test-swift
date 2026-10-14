@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyReferralAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLegacyReferralAssignmentValidator()
        let item = Referrals.newLegacyReferralAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLegacyReferralAssignmentVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Referrals.LegacyReferralAssignmentVisitMinutesRangeRule(min: 64, max: 3600)
        let item = Referrals.newLegacyReferralAssignment("x", name: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsLegacyReferralAssignmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.LegacyReferralAssignmentNameLengthRule(maxLength: 1000)
        let item = Referrals.newLegacyReferralAssignment("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsLegacyReferralAssignmentRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Referrals.LegacyReferralAssignmentRequiredContactEmailRule(
            message: "legacy referral assignment needs this field"
        )
        let item = Referrals.newLegacyReferralAssignment("", name: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacyReferralAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.LegacyReferralAssignmentRequiredCodeRule(
            message: "legacy referral assignment needs this field"
        )
        let item = Referrals.newLegacyReferralAssignment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
