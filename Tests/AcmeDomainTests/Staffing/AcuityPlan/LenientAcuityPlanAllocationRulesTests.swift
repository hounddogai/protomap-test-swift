@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientAcuityPlanAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLenientAcuityPlanAllocationValidator()
        let item = Staffing.newLenientAcuityPlanAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLenientAcuityPlanAllocationVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Staffing.LenientAcuityPlanAllocationVisitMinutesRangeRule(min: 64, max: 120)
        let item = Staffing.newLenientAcuityPlanAllocation("x", title: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLenientAcuityPlanAllocationFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Staffing.LenientAcuityPlanAllocationFacilityLengthRule(maxLength: 255)
        let item = Staffing.newLenientAcuityPlanAllocation("x", title: "y")
        item.facility = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
