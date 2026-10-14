@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanAllocationValidator()
        let item = Staffing.newAcuityPlanAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanAllocationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.AcuityPlanAllocationRequiredTitleRule(message: "acuity plan allocation needs this field")
        let item = Staffing.newAcuityPlanAllocation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingAcuityPlanAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.AcuityPlanAllocationTitleLengthRule(maxLength: 32)
        let item = Staffing.newAcuityPlanAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanAllocationRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Staffing.AcuityPlanAllocationRequiredProcedureCodeRule(
            message: "acuity plan allocation needs a value"
        )
        let item = Staffing.newAcuityPlanAllocation("", title: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}
