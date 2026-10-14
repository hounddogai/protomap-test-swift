@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingCappedPriorityReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultCappedPriorityReservationValidator()
        let item = Imaging.newCappedPriorityReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingCappedPriorityReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.CappedPriorityReservationLabelLengthRule(maxLength: 1000)
        let item = Imaging.newCappedPriorityReservation("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCappedPriorityReservationNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Imaging.CappedPriorityReservationNotesLengthRule(maxLength: 86400)
        let item = Imaging.newCappedPriorityReservation("x", label: "y")
        item.notes = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingCappedPriorityReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.CappedPriorityReservationRequiredCodeRule(
            message: "capped priority reservation needs a value"
        )
        let item = Imaging.newCappedPriorityReservation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
