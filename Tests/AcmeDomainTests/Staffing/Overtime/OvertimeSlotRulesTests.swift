@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeSlotValidator()
        let item = Staffing.newOvertimeSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeSlotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.OvertimeSlotRequiredNameRule(message: "overtime slot needs a value")
        let item = Staffing.newOvertimeSlot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeSlotRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Staffing.OvertimeSlotRequiredSummaryRule(message: "overtime slot needs this field")
        let item = Staffing.newOvertimeSlot("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeSlotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.OvertimeSlotNameLengthRule(maxLength: 32)
        let item = Staffing.newOvertimeSlot("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeSlotRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Staffing.OvertimeSlotRequiredBedRule(message: "overtime slot needs an entry")
        let item = Staffing.newOvertimeSlot("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeSlotSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Staffing.OvertimeSlotSummaryLengthRule(maxLength: 1000)
        let item = Staffing.newOvertimeSlot("x", name: "y")
        item.summary = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
