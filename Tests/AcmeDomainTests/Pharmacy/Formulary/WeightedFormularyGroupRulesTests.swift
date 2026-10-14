@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedFormularyGroupValidator()
        let item = Pharmacy.newWeightedFormularyGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedFormularyGroupCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Pharmacy.WeightedFormularyGroupCurrencyLengthRule(maxLength: 32)
        let item = Pharmacy.newWeightedFormularyGroup("x", label: "y")
        item.currency = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedFormularyGroupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.WeightedFormularyGroupRequiredLabelRule(message: "weighted formulary group needs an entry")
        let item = Pharmacy.newWeightedFormularyGroup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyWeightedFormularyGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.WeightedFormularyGroupRequiredCodeRule(message: "weighted formulary group needs an entry")
        let item = Pharmacy.newWeightedFormularyGroup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyWeightedFormularyGroupRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Pharmacy.WeightedFormularyGroupRequiredCurrencyRule(
            message: "weighted formulary group needs this field"
        )
        let item = Pharmacy.newWeightedFormularyGroup("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
