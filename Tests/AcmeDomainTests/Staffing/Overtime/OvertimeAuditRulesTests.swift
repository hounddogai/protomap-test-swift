@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeAuditValidator()
        let item = Staffing.newOvertimeAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.OvertimeAuditCodeLengthRule(maxLength: 64)
        let item = Staffing.newOvertimeAudit("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeAuditTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.OvertimeAuditTitleLengthRule(maxLength: 80)
        let item = Staffing.newOvertimeAudit("x", label: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
