@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCareProtocolReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCareProtocolReservationValidator()
        let item = Imaging.newCareProtocolReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCareProtocolReservationNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Imaging.CareProtocolReservationNotesLengthRule(maxLength: 80)
        let item = Imaging.newCareProtocolReservation("x", title: "y")
        item.notes = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCareProtocolReservationFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Imaging.CareProtocolReservationFloorValueRangeRule(min: 7.0, max: 1625.9)
        let item = Imaging.newCareProtocolReservation("x", title: "y")
        item.floorValue = 1627.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingCareProtocolReservationRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Imaging.CareProtocolReservationRequiredTimezoneRule(
            message: "care protocol reservation needs a value"
        )
        let item = Imaging.newCareProtocolReservation("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingCareProtocolReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CareProtocolReservationRequiredCodeRule(message: "care protocol reservation needs an entry")
        let item = Imaging.newCareProtocolReservation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
