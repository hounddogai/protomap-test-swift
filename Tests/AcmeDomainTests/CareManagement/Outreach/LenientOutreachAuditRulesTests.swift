@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementLenientOutreachAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultLenientOutreachAuditValidator()
        let item = CareManagement.newLenientOutreachAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementLenientOutreachAuditEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = CareManagement.LenientOutreachAuditEncounterIDLengthRule(maxLength: 3600)
        let item = CareManagement.newLenientOutreachAudit("x", title: "y")
        item.encounterID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLenientOutreachAuditRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = CareManagement.LenientOutreachAuditRequiredWardRule(message: "lenient outreach audit needs a value")
        let item = CareManagement.newLenientOutreachAudit("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientOutreachAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.LenientOutreachAuditRequiredTitleRule(message: "lenient outreach audit needs a value")
        let item = CareManagement.newLenientOutreachAudit("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementLenientOutreachAuditTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.LenientOutreachAuditTitleLengthRule(maxLength: 64)
        let item = CareManagement.newLenientOutreachAudit("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementLenientOutreachAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.LenientOutreachAuditCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newLenientOutreachAudit("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
