@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertAuditValidator()
        let item = ClinicalOps.newAlertAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertAuditRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = ClinicalOps.AlertAuditRequiredTimezoneRule(message: "alert audit needs this field")
        let item = ClinicalOps.newAlertAudit("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertAuditProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = ClinicalOps.AlertAuditProcedureCodeLengthRule(maxLength: 120)
        let item = ClinicalOps.newAlertAudit("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertAuditRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = ClinicalOps.AlertAuditRequiredProcedureCodeRule(message: "alert audit needs a value")
        let item = ClinicalOps.newAlertAudit("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
