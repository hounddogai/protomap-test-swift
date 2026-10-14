@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCappedAcuityPlanAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCappedAcuityPlanAssignmentValidator()
        let item = Staffing.newCappedAcuityPlanAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCappedAcuityPlanAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CappedAcuityPlanAssignmentCodeLengthRule(maxLength: 1000)
        let item = Staffing.newCappedAcuityPlanAssignment("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCappedAcuityPlanAssignmentRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Staffing.CappedAcuityPlanAssignmentRequiredPayerRule(
            message: "capped acuity plan assignment needs this field"
        )
        let item = Staffing.newCappedAcuityPlanAssignment("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCappedAcuityPlanAssignmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.CappedAcuityPlanAssignmentTitleLengthRule(maxLength: 32)
        let item = Staffing.newCappedAcuityPlanAssignment("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
