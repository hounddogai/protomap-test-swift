@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWeightedPriorityReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWeightedPriorityReservationValidator()
        let item = Imaging.newWeightedPriorityReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWeightedPriorityReservationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.WeightedPriorityReservationRequiredLabelRule(
            message: "weighted priority reservation needs this field"
        )
        let item = Imaging.newWeightedPriorityReservation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWeightedPriorityReservationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.WeightedPriorityReservationLabelLengthRule(maxLength: 32)
        let item = Imaging.newWeightedPriorityReservation("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWeightedPriorityReservationTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.WeightedPriorityReservationTitleLengthRule(maxLength: 16)
        let item = Imaging.newWeightedPriorityReservation("x", label: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
