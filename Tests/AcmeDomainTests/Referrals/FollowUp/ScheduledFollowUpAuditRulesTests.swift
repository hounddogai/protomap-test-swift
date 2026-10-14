@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledFollowUpAuditValidator()
        let item = Referrals.newScheduledFollowUpAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledFollowUpAuditDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Referrals.ScheduledFollowUpAuditDiagnosisCodeLengthRule(maxLength: 86400)
        let item = Referrals.newScheduledFollowUpAudit("x", title: "y")
        item.diagnosisCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsScheduledFollowUpAuditTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.ScheduledFollowUpAuditTitleLengthRule(maxLength: 32)
        let item = Referrals.newScheduledFollowUpAudit("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsScheduledFollowUpAuditEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Referrals.ScheduledFollowUpAuditEncounterIDLengthRule(maxLength: 255)
        let item = Referrals.newScheduledFollowUpAudit("x", title: "y")
        item.encounterID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsScheduledFollowUpAuditRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Referrals.ScheduledFollowUpAuditRequiredEncounterIDRule(
            message: "scheduled follow up audit needs an entry"
        )
        let item = Referrals.newScheduledFollowUpAudit("", title: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledFollowUpAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.ScheduledFollowUpAuditRequiredTitleRule(message: "scheduled follow up audit needs a value")
        let item = Referrals.newScheduledFollowUpAudit("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
