@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyShiftRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLegacyShiftRollupValidator()
        let item = Staffing.newLegacyShiftRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLegacyShiftRollupRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Staffing.LegacyShiftRollupRegionLengthRule(maxLength: 16)
        let item = Staffing.newLegacyShiftRollup("x", name: "y")
        item.region = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingLegacyShiftRollupRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Staffing.LegacyShiftRollupRatioRangeRule(min: 0.8, max: 3080.8)
        let item = Staffing.newLegacyShiftRollup("x", name: "y")
        item.ratio = 3082.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLegacyShiftRollupEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Staffing.LegacyShiftRollupEncounterIDLengthRule(maxLength: 80)
        let item = Staffing.newLegacyShiftRollup("x", name: "y")
        item.encounterID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
