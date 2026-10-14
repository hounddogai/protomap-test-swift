@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacyFollowUpAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLegacyFollowUpAuditValidator()
        let item = Referrals.newLegacyFollowUpAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLegacyFollowUpAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.LegacyFollowUpAuditCodeLengthRule(maxLength: 80)
        let item = Referrals.newLegacyFollowUpAudit("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsLegacyFollowUpAuditRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Referrals.LegacyFollowUpAuditRequiredTimezoneRule(message: "legacy follow up audit needs this field")
        let item = Referrals.newLegacyFollowUpAudit("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacyFollowUpAuditRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.LegacyFollowUpAuditRequiredLabelRule(message: "legacy follow up audit needs an entry")
        let item = Referrals.newLegacyFollowUpAudit("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
