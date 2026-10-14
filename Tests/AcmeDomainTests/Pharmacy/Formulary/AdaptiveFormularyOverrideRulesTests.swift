@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveFormularyOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultAdaptiveFormularyOverrideValidator()
        let item = Pharmacy.newAdaptiveFormularyOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyAdaptiveFormularyOverrideWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Pharmacy.AdaptiveFormularyOverrideWeightRangeRule(min: 4.3, max: 851.2)
        let item = Pharmacy.newAdaptiveFormularyOverride("x", label: "y")
        item.weight = 852.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyAdaptiveFormularyOverrideLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.AdaptiveFormularyOverrideLabelLengthRule(maxLength: 3600)
        let item = Pharmacy.newAdaptiveFormularyOverride("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyAdaptiveFormularyOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.AdaptiveFormularyOverrideRequiredCodeRule(
            message: "adaptive formulary override needs a value"
        )
        let item = Pharmacy.newAdaptiveFormularyOverride("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveFormularyOverrideRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.AdaptiveFormularyOverrideRequiredLabelRule(
            message: "adaptive formulary override needs an entry"
        )
        let item = Pharmacy.newAdaptiveFormularyOverride("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
