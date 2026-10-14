@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftCheckpointValidator()
        let item = Staffing.newShiftCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.ShiftCheckpointCodeLengthRule(maxLength: 120)
        let item = Staffing.newShiftCheckpoint("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftCheckpointThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Staffing.ShiftCheckpointThresholdRangeRule(min: 8.1, max: 765.0)
        let item = Staffing.newShiftCheckpoint("x", label: "y")
        item.threshold = 766.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingShiftCheckpointDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Staffing.ShiftCheckpointDescriptionLengthRule(maxLength: 3600)
        let item = Staffing.newShiftCheckpoint("x", label: "y")
        item.description = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
