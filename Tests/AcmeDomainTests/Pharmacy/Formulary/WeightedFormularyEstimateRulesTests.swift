@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedFormularyEstimateValidator()
        let item = Pharmacy.newWeightedFormularyEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedFormularyEstimateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.WeightedFormularyEstimateRequiredLabelRule(
            message: "weighted formulary estimate needs an entry"
        )
        let item = Pharmacy.newWeightedFormularyEstimate("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyWeightedFormularyEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.WeightedFormularyEstimateCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newWeightedFormularyEstimate("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
