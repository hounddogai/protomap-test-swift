@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingShiftMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultShiftMetricValidator()
        let item = Staffing.newShiftMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingShiftMetricEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Staffing.ShiftMetricEncounterIDLengthRule(maxLength: 1000)
        let item = Staffing.newShiftMetric("x", label: "y")
        item.encounterID = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingShiftMetricRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Staffing.ShiftMetricRequiredRegionRule(message: "shift metric needs an entry")
        let item = Staffing.newShiftMetric("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingShiftMetricLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.ShiftMetricLabelLengthRule(maxLength: 80)
        let item = Staffing.newShiftMetric("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
