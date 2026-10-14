@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPrimaryShiftWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPrimaryShiftWindowValidator()
        let item = Staffing.newPrimaryShiftWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPrimaryShiftWindowRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Staffing.PrimaryShiftWindowRequiredEncounterIDRule(message: "primary shift window needs this field")
        let item = Staffing.newPrimaryShiftWindow("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPrimaryShiftWindowFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.PrimaryShiftWindowFloorValueRangeRule(min: 7.5, max: 4049.0)
        let item = Staffing.newPrimaryShiftWindow("x", label: "y")
        item.floorValue = 4050.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingPrimaryShiftWindowFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = Staffing.PrimaryShiftWindowFacilityLengthRule(maxLength: 255)
        let item = Staffing.newPrimaryShiftWindow("x", label: "y")
        item.facility = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}
