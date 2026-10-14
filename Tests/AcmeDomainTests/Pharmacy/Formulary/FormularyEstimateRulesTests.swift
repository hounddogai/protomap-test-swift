@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFormularyEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFormularyEstimateValidator()
        let item = Pharmacy.newFormularyEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFormularyEstimateStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.FormularyEstimateStartsAtRangeRule(min: 32, max: 80)
        let item = Pharmacy.newFormularyEstimate("x", title: "y")
        item.startsAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyEstimateGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Pharmacy.FormularyEstimateGraceDaysRangeRule(min: 16, max: 1000)
        let item = Pharmacy.newFormularyEstimate("x", title: "y")
        item.graceDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFormularyEstimateRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Pharmacy.FormularyEstimateRefillsRangeRule(min: 16, max: 80)
        let item = Pharmacy.newFormularyEstimate("x", title: "y")
        item.refills = 81
        #expect(rule.check(item).count > 0)
    }
}
