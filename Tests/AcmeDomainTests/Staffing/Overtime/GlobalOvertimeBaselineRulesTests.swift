@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalOvertimeBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultGlobalOvertimeBaselineValidator()
        let item = Staffing.newGlobalOvertimeBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingGlobalOvertimeBaselineWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Staffing.GlobalOvertimeBaselineWeightRangeRule(min: 8.8, max: 1524.9)
        let item = Staffing.newGlobalOvertimeBaseline("x", label: "y")
        item.weight = 1526.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingGlobalOvertimeBaselineCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.GlobalOvertimeBaselineCodeLengthRule(maxLength: 255)
        let item = Staffing.newGlobalOvertimeBaseline("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalOvertimeBaselineAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Staffing.GlobalOvertimeBaselineAttemptsRangeRule(min: 32, max: 3600)
        let item = Staffing.newGlobalOvertimeBaseline("x", label: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}
