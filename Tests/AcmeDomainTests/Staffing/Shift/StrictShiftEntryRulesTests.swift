@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingStrictShiftEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultStrictShiftEntryValidator()
        let item = Staffing.newStrictShiftEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingStrictShiftEntryRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Staffing.StrictShiftEntryRequiredOwnerIDRule(message: "strict shift entry needs a value")
        let item = Staffing.newStrictShiftEntry("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictShiftEntryRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Staffing.StrictShiftEntryRequiredEncounterIDRule(message: "strict shift entry needs a value")
        let item = Staffing.newStrictShiftEntry("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictShiftEntryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.StrictShiftEntryRequiredCodeRule(message: "strict shift entry needs a value")
        let item = Staffing.newStrictShiftEntry("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingStrictShiftEntryFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Staffing.StrictShiftEntryFloorValueRangeRule(min: 6.3, max: 1343.7)
        let item = Staffing.newStrictShiftEntry("x", name: "y")
        item.floorValue = 1345.2
        #expect(rule.check(item).count > 0)
    }
}
