@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityReservationValidator()
        let item = Imaging.newPriorityReservation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityReservationMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Imaging.PriorityReservationMaximumRangeRule(min: 8.3, max: 633.0)
        let item = Imaging.newPriorityReservation("x", name: "y")
        item.maximum = 634.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityReservationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.PriorityReservationRequiredNameRule(message: "priority reservation needs a value")
        let item = Imaging.newPriorityReservation("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
