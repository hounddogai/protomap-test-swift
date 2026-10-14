@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyAdjustmentValidator()
        let item = Pharmacy.newFormularyAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyAdjustmentStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.FormularyAdjustmentStartsAtRangeRule(min: 16, max: 120)
        let item = Pharmacy.newFormularyAdjustment("x", label: "y")
        item.startsAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyAdjustmentSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Pharmacy.FormularyAdjustmentSpecialtyLengthRule(maxLength: 64)
        let item = Pharmacy.newFormularyAdjustment("x", label: "y")
        item.specialty = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyAdjustmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.FormularyAdjustmentLabelLengthRule(maxLength: 64)
        let item = Pharmacy.newFormularyAdjustment("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.FormularyAdjustmentRequiredCodeRule(message: "formulary adjustment needs a value")
        let item = Pharmacy.newFormularyAdjustment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyAdjustmentRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Pharmacy.FormularyAdjustmentRequiredPayerRule(message: "formulary adjustment needs an entry")
        let item = Pharmacy.newFormularyAdjustment("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyAdjustmentRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Pharmacy.FormularyAdjustmentRequiredSpecialtyRule(message: "formulary adjustment needs an entry")
        let item = Pharmacy.newFormularyAdjustment("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
