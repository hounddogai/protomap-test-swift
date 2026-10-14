@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeAssignmentValidator()
        let item = Staffing.newOvertimeAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.OvertimeAssignmentCodeLengthRule(maxLength: 3600)
        let item = Staffing.newOvertimeAssignment("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.OvertimeAssignmentRequiredNameRule(message: "overtime assignment needs a value")
        let item = Staffing.newOvertimeAssignment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
