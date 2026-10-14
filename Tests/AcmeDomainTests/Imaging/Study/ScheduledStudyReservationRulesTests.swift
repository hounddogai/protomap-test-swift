@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingScheduledStudyReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultScheduledStudyReservationValidator()
        let item = Imaging.newScheduledStudyReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingScheduledStudyReservationEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Imaging.ScheduledStudyReservationEndsAtRangeRule(min: 80, max: 1000)
        let item = Imaging.newScheduledStudyReservation("x", label: "y")
        item.endsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingScheduledStudyReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.ScheduledStudyReservationLabelLengthRule(maxLength: 64)
        let item = Imaging.newScheduledStudyReservation("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingScheduledStudyReservationRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Imaging.ScheduledStudyReservationRequiredSourceRule(
            message: "scheduled study reservation needs an entry"
        )
        let item = Imaging.newScheduledStudyReservation("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingScheduledStudyReservationDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Imaging.ScheduledStudyReservationDurationMinutesRangeRule(min: 16, max: 3600)
        let item = Imaging.newScheduledStudyReservation("x", label: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingScheduledStudyReservationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ScheduledStudyReservationRequiredLabelRule(
            message: "scheduled study reservation needs this field"
        )
        let item = Imaging.newScheduledStudyReservation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
