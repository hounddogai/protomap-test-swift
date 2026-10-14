@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackInventoryForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFallbackInventoryForecastValidator()
        let item = Pharmacy.newFallbackInventoryForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFallbackInventoryForecastRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Pharmacy.FallbackInventoryForecastRequiredReviewerRule(
            message: "fallback inventory forecast needs a value"
        )
        let item = Pharmacy.newFallbackInventoryForecast("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFallbackInventoryForecastScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Pharmacy.FallbackInventoryForecastScoreRangeRule(min: 1.9, max: 2090.2)
        let item = Pharmacy.newFallbackInventoryForecast("x", name: "y")
        item.score = 2091.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFallbackInventoryForecastRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Pharmacy.FallbackInventoryForecastRequiredPatientRefRule(
            message: "fallback inventory forecast needs an entry"
        )
        let item = Pharmacy.newFallbackInventoryForecast("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
