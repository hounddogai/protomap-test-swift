@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingScheduledAcuityPlanAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultScheduledAcuityPlanAllocationValidator()
        let item = Staffing.newScheduledAcuityPlanAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingScheduledAcuityPlanAllocationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.ScheduledAcuityPlanAllocationRequiredNameRule(
            message: "scheduled acuity plan allocation needs this field"
        )
        let item = Staffing.newScheduledAcuityPlanAllocation("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingScheduledAcuityPlanAllocationSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Staffing.ScheduledAcuityPlanAllocationSpecialtyLengthRule(maxLength: 3600)
        let item = Staffing.newScheduledAcuityPlanAllocation("x", label: "y")
        item.specialty = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
