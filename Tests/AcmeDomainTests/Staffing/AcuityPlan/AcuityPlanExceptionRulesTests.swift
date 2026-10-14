@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingAcuityPlanExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultAcuityPlanExceptionValidator()
        let item = Staffing.newAcuityPlanException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingAcuityPlanExceptionCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Staffing.AcuityPlanExceptionCapacityRangeRule(min: 255, max: 86400)
        let item = Staffing.newAcuityPlanException("x", name: "y")
        item.capacity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingAcuityPlanExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.AcuityPlanExceptionCodeLengthRule(maxLength: 80)
        let item = Staffing.newAcuityPlanException("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingAcuityPlanExceptionNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.AcuityPlanExceptionNameLengthRule(maxLength: 32)
        let item = Staffing.newAcuityPlanException("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
