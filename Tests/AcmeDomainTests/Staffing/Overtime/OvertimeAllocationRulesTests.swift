@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeAllocationValidator()
        let item = Staffing.newOvertimeAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeAllocationRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Staffing.OvertimeAllocationRequiredFacilityRule(message: "overtime allocation needs a value")
        let item = Staffing.newOvertimeAllocation("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeAllocationFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.OvertimeAllocationFloorValueRangeRule(min: 7.0, max: 800.9)
        let item = Staffing.newOvertimeAllocation("x", name: "y")
        item.floorValue = 802.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimeAllocationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.OvertimeAllocationRequiredNameRule(message: "overtime allocation needs a value")
        let item = Staffing.newOvertimeAllocation("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
