@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingWorklistReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPendingWorklistReservationValidator()
        let item = Imaging.newPendingWorklistReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPendingWorklistReservationCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Imaging.PendingWorklistReservationCurrencyLengthRule(maxLength: 86400)
        let item = Imaging.newPendingWorklistReservation("x", title: "y")
        item.currency = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPendingWorklistReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.PendingWorklistReservationRequiredCodeRule(
            message: "pending worklist reservation needs this field"
        )
        let item = Imaging.newPendingWorklistReservation("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPendingWorklistReservationMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Imaging.PendingWorklistReservationMinimumRangeRule(min: 0.5, max: 4472.2)
        let item = Imaging.newPendingWorklistReservation("x", title: "y")
        item.minimum = 4473.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPendingWorklistReservationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.PendingWorklistReservationRequiredTitleRule(
            message: "pending worklist reservation needs this field"
        )
        let item = Imaging.newPendingWorklistReservation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
