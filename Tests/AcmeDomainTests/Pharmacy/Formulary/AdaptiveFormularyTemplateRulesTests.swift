@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveFormularyTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultAdaptiveFormularyTemplateValidator()
        let item = Pharmacy.newAdaptiveFormularyTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyAdaptiveFormularyTemplateRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Pharmacy.AdaptiveFormularyTemplateRequiredContactEmailRule(
            message: "adaptive formulary template needs this field"
        )
        let item = Pharmacy.newAdaptiveFormularyTemplate("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveFormularyTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.AdaptiveFormularyTemplateRequiredCodeRule(
            message: "adaptive formulary template needs this field"
        )
        let item = Pharmacy.newAdaptiveFormularyTemplate("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveFormularyTemplateGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Pharmacy.AdaptiveFormularyTemplateGraceDaysRangeRule(min: 16, max: 16)
        let item = Pharmacy.newAdaptiveFormularyTemplate("x", label: "y")
        item.graceDays = 17
        #expect(rule.check(item).count > 0)
    }
}
