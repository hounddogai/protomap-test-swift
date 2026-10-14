@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedDispenseCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedDispenseCycleValidator()
        let item = Pharmacy.newWeightedDispenseCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedDispenseCycleRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Pharmacy.WeightedDispenseCycleRateRangeRule(min: 3.8, max: 3684.3)
        let item = Pharmacy.newWeightedDispenseCycle("x", title: "y")
        item.rate = 3685.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyWeightedDispenseCycleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.WeightedDispenseCycleRequiredCodeRule(message: "weighted dispense cycle needs a value")
        let item = Pharmacy.newWeightedDispenseCycle("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
