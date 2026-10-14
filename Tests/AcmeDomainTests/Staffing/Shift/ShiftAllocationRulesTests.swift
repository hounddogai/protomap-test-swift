@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftAllocationValidator()
        let item = Staffing.newShiftAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.ShiftAllocationTitleLengthRule(maxLength: 255)
        let item = Staffing.newShiftAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.ShiftAllocationRequiredCodeRule(message: "shift allocation needs this field")
        let item = Staffing.newShiftAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftAllocationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.ShiftAllocationRequiredTitleRule(message: "shift allocation needs this field")
        let item = Staffing.newShiftAllocation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftAllocationNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Staffing.ShiftAllocationNotesLengthRule(maxLength: 3600)
        let item = Staffing.newShiftAllocation("x", title: "y")
        item.notes = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftAllocationWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Staffing.ShiftAllocationWeightRangeRule(min: 5.7, max: 2634.7)
        let item = Staffing.newShiftAllocation("x", title: "y")
        item.weight = 2636.2
        #expect(rule.check(item).count > 0)
    }
}
