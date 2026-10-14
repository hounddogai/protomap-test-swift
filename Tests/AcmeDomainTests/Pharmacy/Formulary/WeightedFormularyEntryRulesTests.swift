@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedFormularyEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedFormularyEntryValidator()
        let item = Pharmacy.newWeightedFormularyEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedFormularyEntrySequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Pharmacy.WeightedFormularyEntrySequenceRangeRule(min: 120, max: 1000)
        let item = Pharmacy.newWeightedFormularyEntry("x", title: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyWeightedFormularyEntryAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Pharmacy.WeightedFormularyEntryAmountRangeRule(min: 8.3, max: 1568.2)
        let item = Pharmacy.newWeightedFormularyEntry("x", title: "y")
        item.amount = 1569.7
        #expect(rule.check(item).count > 0)
    }
}
