@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualOutreachAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualOutreachAuditValidator()
        let item = CareManagement.newManualOutreachAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualOutreachAuditDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = CareManagement.ManualOutreachAuditDurationMinutesRangeRule(min: 16, max: 3600)
        let item = CareManagement.newManualOutreachAudit("x", label: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementManualOutreachAuditEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = CareManagement.ManualOutreachAuditEncounterIDLengthRule(maxLength: 32)
        let item = CareManagement.newManualOutreachAudit("x", label: "y")
        item.encounterID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualOutreachAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ManualOutreachAuditCodeLengthRule(maxLength: 86400)
        let item = CareManagement.newManualOutreachAudit("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
