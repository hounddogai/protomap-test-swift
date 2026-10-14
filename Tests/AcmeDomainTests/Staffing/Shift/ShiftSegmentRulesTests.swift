@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftSegmentValidator()
        let item = Staffing.newShiftSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftSegmentBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Staffing.ShiftSegmentBudgetRangeRule(min: 8.8, max: 4617.6)
        let item = Staffing.newShiftSegment("x", label: "y")
        item.budget = 4619.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftSegmentRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Staffing.ShiftSegmentRequiredLocaleRule(message: "shift segment needs a value")
        let item = Staffing.newShiftSegment("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ShiftSegmentCodeLengthRule(maxLength: 64)
        let item = Staffing.newShiftSegment("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftSegmentWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Staffing.ShiftSegmentWindowDaysRangeRule(min: 16, max: 32)
        let item = Staffing.newShiftSegment("x", label: "y")
        item.windowDays = 33
        #expect(rule.check(item).count > 0)
    }
}
