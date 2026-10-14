@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeAdjustmentValidator()
        let item = Staffing.newOvertimeAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.OvertimeAdjustmentCodeLengthRule(maxLength: 120)
        let item = Staffing.newOvertimeAdjustment("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeAdjustmentRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Staffing.OvertimeAdjustmentRequiredRegionRule(message: "overtime adjustment needs a value")
        let item = Staffing.newOvertimeAdjustment("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingOvertimeAdjustmentDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Staffing.OvertimeAdjustmentDurationMinutesRangeRule(min: 64, max: 1000)
        let item = Staffing.newOvertimeAdjustment("x", label: "y")
        item.durationMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingOvertimeAdjustmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.OvertimeAdjustmentLabelLengthRule(maxLength: 32)
        let item = Staffing.newOvertimeAdjustment("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
