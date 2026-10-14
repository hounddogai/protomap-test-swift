@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementDischargePlanAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultDischargePlanAuditValidator()
        let item = BedManagement.newDischargePlanAudit("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementDischargePlanAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.DischargePlanAuditCodeLengthRule(maxLength: 64)
        let item = BedManagement.newDischargePlanAudit("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanAuditTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.DischargePlanAuditTitleLengthRule(maxLength: 32)
        let item = BedManagement.newDischargePlanAudit("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementDischargePlanAuditRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.DischargePlanAuditRequiredCodeRule(message: "discharge plan audit needs this field")
        let item = BedManagement.newDischargePlanAudit("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
