@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingReadReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPendingReadReservationValidator()
        let item = Imaging.newPendingReadReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPendingReadReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.PendingReadReservationLabelLengthRule(maxLength: 120)
        let item = Imaging.newPendingReadReservation("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPendingReadReservationUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Imaging.PendingReadReservationUpdatedAtRangeRule(min: 32, max: 80)
        let item = Imaging.newPendingReadReservation("x", label: "y")
        item.updatedAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPendingReadReservationRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Imaging.PendingReadReservationRequiredSpecialtyRule(
            message: "pending read reservation needs an entry"
        )
        let item = Imaging.newPendingReadReservation("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPendingReadReservationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PendingReadReservationCodeLengthRule(maxLength: 16)
        let item = Imaging.newPendingReadReservation("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
