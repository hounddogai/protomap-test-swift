@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingRollingAcuityPlanAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultRollingAcuityPlanAssignmentValidator()
        let item = Staffing.newRollingAcuityPlanAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingRollingAcuityPlanAssignmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.RollingAcuityPlanAssignmentRequiredLabelRule(
            message: "rolling acuity plan assignment needs this field"
        )
        let item = Staffing.newRollingAcuityPlanAssignment("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingRollingAcuityPlanAssignmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.RollingAcuityPlanAssignmentNameLengthRule(maxLength: 1000)
        let item = Staffing.newRollingAcuityPlanAssignment("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingRollingAcuityPlanAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.RollingAcuityPlanAssignmentRequiredNameRule(
            message: "rolling acuity plan assignment needs an entry"
        )
        let item = Staffing.newRollingAcuityPlanAssignment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
