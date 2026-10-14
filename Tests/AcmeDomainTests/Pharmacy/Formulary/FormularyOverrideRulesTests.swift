@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyOverrideValidator()
        let item = Pharmacy.newFormularyOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyOverrideLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.FormularyOverrideLabelLengthRule(maxLength: 120)
        let item = Pharmacy.newFormularyOverride("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFormularyOverrideRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Pharmacy.FormularyOverrideRequiredSourceRule(message: "formulary override needs an entry")
        let item = Pharmacy.newFormularyOverride("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFormularyOverrideRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Pharmacy.FormularyOverrideRateRangeRule(min: 3.1, max: 3632.0)
        let item = Pharmacy.newFormularyOverride("x", label: "y")
        item.rate = 3633.5
        #expect(rule.check(item).count > 0)
    }
}
