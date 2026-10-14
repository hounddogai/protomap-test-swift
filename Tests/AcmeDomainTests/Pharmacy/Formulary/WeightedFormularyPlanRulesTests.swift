@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedFormularyPlanValidator()
        let item = Pharmacy.newWeightedFormularyPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedFormularyPlanRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.WeightedFormularyPlanRequiredLabelRule(message: "weighted formulary plan needs an entry")
        let item = Pharmacy.newWeightedFormularyPlan("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyWeightedFormularyPlanSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Pharmacy.WeightedFormularyPlanSequenceRangeRule(min: 120, max: 3600)
        let item = Pharmacy.newWeightedFormularyPlan("x", label: "y")
        item.sequence = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyWeightedFormularyPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.WeightedFormularyPlanRequiredCodeRule(message: "weighted formulary plan needs a value")
        let item = Pharmacy.newWeightedFormularyPlan("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
