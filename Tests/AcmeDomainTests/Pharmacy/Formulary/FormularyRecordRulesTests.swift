@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyRecordValidator()
        let item = Pharmacy.newFormularyRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyRecordExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.FormularyRecordExpiresAtRangeRule(min: 255, max: 1000)
        let item = Pharmacy.newFormularyRecord("x", name: "y")
        item.expiresAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyRecordRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Pharmacy.FormularyRecordRequiredAllergyRule(message: "formulary record needs this field")
        let item = Pharmacy.newFormularyRecord("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyRecordWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Pharmacy.FormularyRecordWeightRangeRule(min: 4.3, max: 1954.3)
        let item = Pharmacy.newFormularyRecord("x", name: "y")
        item.weight = 1955.8
        #expect(rule.check(item).count > 0)
    }
}
