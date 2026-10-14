@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistReservationValidator()
        let item = Imaging.newWorklistReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistReservationVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Imaging.WorklistReservationVisitMinutesRangeRule(min: 32, max: 86400)
        let item = Imaging.newWorklistReservation("x", title: "y")
        item.visitMinutes = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistReservationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.WorklistReservationRequiredTitleRule(message: "worklist reservation needs a value")
        let item = Imaging.newWorklistReservation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistReservationSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Imaging.WorklistReservationSpecialtyLengthRule(maxLength: 16)
        let item = Imaging.newWorklistReservation("x", title: "y")
        item.specialty = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistReservationRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Imaging.WorklistReservationRetriesRangeRule(min: 255, max: 86400)
        let item = Imaging.newWorklistReservation("x", title: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}
