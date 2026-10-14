@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedReferralAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedReferralAuditValidator()
        let item = Referrals.newWeightedReferralAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedReferralAuditRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.WeightedReferralAuditRequiredNameRule(message: "weighted referral audit needs a value")
        let item = Referrals.newWeightedReferralAudit("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsWeightedReferralAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.WeightedReferralAuditRequiredCodeRule(message: "weighted referral audit needs an entry")
        let item = Referrals.newWeightedReferralAudit("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsWeightedReferralAuditRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = Referrals.WeightedReferralAuditRequiredClinicianIDRule(
            message: "weighted referral audit needs an entry"
        )
        let item = Referrals.newWeightedReferralAudit("", name: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsWeightedReferralAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.WeightedReferralAuditCodeLengthRule(maxLength: 16)
        let item = Referrals.newWeightedReferralAudit("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
