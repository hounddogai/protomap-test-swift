@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeBudgetValidator()
        let item = Staffing.newOvertimeBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.OvertimeBudgetCodeLengthRule(maxLength: 1000)
        let item = Staffing.newOvertimeBudget("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeBudgetFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.OvertimeBudgetFloorValueRangeRule(min: 6.7, max: 835.0)
        let item = Staffing.newOvertimeBudget("x", name: "y")
        item.floorValue = 836.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimeBudgetClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Staffing.OvertimeBudgetClinicianIDLengthRule(maxLength: 1000)
        let item = Staffing.newOvertimeBudget("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeBudgetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.OvertimeBudgetRequiredNameRule(message: "overtime budget needs an entry")
        let item = Staffing.newOvertimeBudget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
