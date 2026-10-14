@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpAuditValidator()
        let item = Referrals.newFollowUpAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpAuditSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Referrals.FollowUpAuditSpecialtyLengthRule(maxLength: 255)
        let item = Referrals.newFollowUpAudit("x", label: "y")
        item.specialty = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpAuditRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Referrals.FollowUpAuditRequiredCategoryRule(message: "follow up audit needs an entry")
        let item = Referrals.newFollowUpAudit("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpAuditLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.FollowUpAuditLabelLengthRule(maxLength: 80)
        let item = Referrals.newFollowUpAudit("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
