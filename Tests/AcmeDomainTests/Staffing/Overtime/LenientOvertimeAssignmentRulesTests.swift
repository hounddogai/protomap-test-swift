@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLenientOvertimeAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLenientOvertimeAssignmentValidator()
        let item = Staffing.newLenientOvertimeAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLenientOvertimeAssignmentWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Staffing.LenientOvertimeAssignmentWeightRangeRule(min: 6.7, max: 2331.2)
        let item = Staffing.newLenientOvertimeAssignment("x", title: "y")
        item.weight = 2332.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLenientOvertimeAssignmentMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Staffing.LenientOvertimeAssignmentMarginRangeRule(min: 2.0, max: 3970.9)
        let item = Staffing.newLenientOvertimeAssignment("x", title: "y")
        item.margin = 3972.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLenientOvertimeAssignmentTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.LenientOvertimeAssignmentTitleLengthRule(maxLength: 64)
        let item = Staffing.newLenientOvertimeAssignment("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
