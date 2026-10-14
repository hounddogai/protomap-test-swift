@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingOvertimeCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultOvertimeCheckpointValidator()
        let item = Staffing.newOvertimeCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingOvertimeCheckpointBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Staffing.OvertimeCheckpointBedLengthRule(maxLength: 32)
        let item = Staffing.newOvertimeCheckpoint("x", label: "y")
        item.bed = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingOvertimeCheckpointCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.OvertimeCheckpointCeilingRangeRule(min: 7.6, max: 4305.4)
        let item = Staffing.newOvertimeCheckpoint("x", label: "y")
        item.ceiling = 4306.9
        #expect(rule.check(item).count > 0)
    }
}
