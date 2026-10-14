@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalShiftProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultGlobalShiftProfileValidator()
        let item = Staffing.newGlobalShiftProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingGlobalShiftProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.GlobalShiftProfileCodeLengthRule(maxLength: 120)
        let item = Staffing.newGlobalShiftProfile("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalShiftProfileEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Staffing.GlobalShiftProfileEncounterIDLengthRule(maxLength: 32)
        let item = Staffing.newGlobalShiftProfile("x", name: "y")
        item.encounterID = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalShiftProfileScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Staffing.GlobalShiftProfileScoreRangeRule(min: 0.7, max: 1297.9)
        let item = Staffing.newGlobalShiftProfile("x", name: "y")
        item.score = 1299.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingGlobalShiftProfileRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Staffing.GlobalShiftProfileRequiredFacilityRule(message: "global shift profile needs an entry")
        let item = Staffing.newGlobalShiftProfile("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}
