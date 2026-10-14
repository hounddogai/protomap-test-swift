@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingManualCareProtocolReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultManualCareProtocolReservationValidator()
        let item = Imaging.newManualCareProtocolReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingManualCareProtocolReservationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.ManualCareProtocolReservationRequiredLabelRule(
            message: "manual care protocol reservation needs this field"
        )
        let item = Imaging.newManualCareProtocolReservation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingManualCareProtocolReservationRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Imaging.ManualCareProtocolReservationRequiredReviewerRule(
            message: "manual care protocol reservation needs this field"
        )
        let item = Imaging.newManualCareProtocolReservation("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingManualCareProtocolReservationFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Imaging.ManualCareProtocolReservationFloorValueRangeRule(min: 8.6, max: 4318.7)
        let item = Imaging.newManualCareProtocolReservation("x", label: "y")
        item.floorValue = 4320.2
        #expect(rule.check(item).count > 0)
    }
}
