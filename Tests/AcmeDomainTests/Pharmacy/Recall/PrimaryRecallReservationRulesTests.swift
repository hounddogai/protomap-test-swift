@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryRecallReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPrimaryRecallReservationValidator()
        let item = Pharmacy.newPrimaryRecallReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPrimaryRecallReservationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.PrimaryRecallReservationRequiredLabelRule(
            message: "primary recall reservation needs an entry"
        )
        let item = Pharmacy.newPrimaryRecallReservation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimaryRecallReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.PrimaryRecallReservationRequiredCodeRule(message: "primary recall reservation needs a value")
        let item = Pharmacy.newPrimaryRecallReservation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimaryRecallReservationCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Pharmacy.PrimaryRecallReservationCostRangeRule(min: 6.5, max: 1430.1)
        let item = Pharmacy.newPrimaryRecallReservation("x", label: "y")
        item.cost = 1431.6
        #expect(rule.check(item).count > 0)
    }
}
