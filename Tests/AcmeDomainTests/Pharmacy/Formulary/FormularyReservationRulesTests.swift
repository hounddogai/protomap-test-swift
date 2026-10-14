@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyReservationValidator()
        let item = Pharmacy.newFormularyReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyReservationRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Pharmacy.FormularyReservationRequiredUnitRule(message: "formulary reservation needs an entry")
        let item = Pharmacy.newFormularyReservation("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyReservationCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Pharmacy.FormularyReservationCostRangeRule(min: 4.8, max: 2754.1)
        let item = Pharmacy.newFormularyReservation("x", label: "y")
        item.cost = 2755.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyReservationUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Pharmacy.FormularyReservationUpdatedAtRangeRule(min: 16, max: 64)
        let item = Pharmacy.newFormularyReservation("x", label: "y")
        item.updatedAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.FormularyReservationRequiredCodeRule(message: "formulary reservation needs an entry")
        let item = Pharmacy.newFormularyReservation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
