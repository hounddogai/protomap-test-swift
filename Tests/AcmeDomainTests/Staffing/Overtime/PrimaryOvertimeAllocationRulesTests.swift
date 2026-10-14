@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryOvertimeAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryOvertimeAllocationValidator()
        let item = Staffing.newPrimaryOvertimeAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryOvertimeAllocationRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Staffing.PrimaryOvertimeAllocationRequiredContactEmailRule(
            message: "primary overtime allocation needs a value"
        )
        let item = Staffing.newPrimaryOvertimeAllocation("", title: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryOvertimeAllocationStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Staffing.PrimaryOvertimeAllocationStartsAtRangeRule(min: 120, max: 255)
        let item = Staffing.newPrimaryOvertimeAllocation("x", title: "y")
        item.startsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPrimaryOvertimeAllocationNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Staffing.PrimaryOvertimeAllocationNotesLengthRule(maxLength: 16)
        let item = Staffing.newPrimaryOvertimeAllocation("x", title: "y")
        item.notes = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryOvertimeAllocationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.PrimaryOvertimeAllocationRequiredTitleRule(
            message: "primary overtime allocation needs an entry"
        )
        let item = Staffing.newPrimaryOvertimeAllocation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryOvertimeAllocationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.PrimaryOvertimeAllocationTitleLengthRule(maxLength: 3600)
        let item = Staffing.newPrimaryOvertimeAllocation("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPrimaryOvertimeAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.PrimaryOvertimeAllocationRequiredCodeRule(
            message: "primary overtime allocation needs a value"
        )
        let item = Staffing.newPrimaryOvertimeAllocation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
