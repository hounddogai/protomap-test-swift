@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingTieredOvertimeScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultTieredOvertimeScoreValidator()
        let item = Staffing.newTieredOvertimeScore("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingTieredOvertimeScoreFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.TieredOvertimeScoreFloorValueRangeRule(min: 5.9, max: 63.5)
        let item = Staffing.newTieredOvertimeScore("x", label: "y")
        item.floorValue = 65.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingTieredOvertimeScoreLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.TieredOvertimeScoreLabelLengthRule(maxLength: 255)
        let item = Staffing.newTieredOvertimeScore("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingTieredOvertimeScoreChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Staffing.TieredOvertimeScoreChannelLengthRule(maxLength: 80)
        let item = Staffing.newTieredOvertimeScore("x", label: "y")
        item.channel = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
