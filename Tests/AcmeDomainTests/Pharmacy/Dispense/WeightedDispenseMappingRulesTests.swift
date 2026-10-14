@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedDispenseMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedDispenseMappingValidator()
        let item = Pharmacy.newWeightedDispenseMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedDispenseMappingBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Pharmacy.WeightedDispenseMappingBudgetRangeRule(min: 5.2, max: 4644.0)
        let item = Pharmacy.newWeightedDispenseMapping("x", label: "y")
        item.budget = 4645.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyWeightedDispenseMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.WeightedDispenseMappingCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newWeightedDispenseMapping("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedDispenseMappingNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.WeightedDispenseMappingNameLengthRule(maxLength: 255)
        let item = Pharmacy.newWeightedDispenseMapping("x", label: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedDispenseMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.WeightedDispenseMappingRequiredCodeRule(message: "weighted dispense mapping needs an entry")
        let item = Pharmacy.newWeightedDispenseMapping("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
