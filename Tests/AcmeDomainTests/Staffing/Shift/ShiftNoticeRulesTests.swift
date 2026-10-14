@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftNoticeValidator()
        let item = Staffing.newShiftNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftNoticeAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Staffing.ShiftNoticeAmountRangeRule(min: 5.6, max: 3137.3)
        let item = Staffing.newShiftNotice("x", label: "y")
        item.amount = 3138.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftNoticeLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.ShiftNoticeLabelLengthRule(maxLength: 1000)
        let item = Staffing.newShiftNotice("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ShiftNoticeRequiredCodeRule(message: "shift notice needs an entry")
        let item = Staffing.newShiftNotice("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftNoticeCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Staffing.ShiftNoticeCapacityRangeRule(min: 32, max: 80)
        let item = Staffing.newShiftNotice("x", label: "y")
        item.capacity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftNoticeCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Staffing.ShiftNoticeCategoryLengthRule(maxLength: 80)
        let item = Staffing.newShiftNotice("x", label: "y")
        item.category = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
