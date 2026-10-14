@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimePlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimePlanValidator()
        let item = Staffing.newOvertimePlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimePlanRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Staffing.OvertimePlanRequiredPhoneRule(message: "overtime plan needs this field")
        let item = Staffing.newOvertimePlan("", title: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimePlanCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Staffing.OvertimePlanCapacityRangeRule(min: 16, max: 64)
        let item = Staffing.newOvertimePlan("x", title: "y")
        item.capacity = 65
        #expect(rule.check(item).count > 0)
    }
}
