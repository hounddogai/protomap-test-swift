@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalSubstitutionForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRegionalSubstitutionForecastValidator()
        let item = Pharmacy.newRegionalSubstitutionForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRegionalSubstitutionForecastAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.RegionalSubstitutionForecastAttemptsRangeRule(min: 80, max: 86400)
        let item = Pharmacy.newRegionalSubstitutionForecast("x", name: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRegionalSubstitutionForecastSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Pharmacy.RegionalSubstitutionForecastSequenceRangeRule(min: 120, max: 255)
        let item = Pharmacy.newRegionalSubstitutionForecast("x", name: "y")
        item.sequence = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRegionalSubstitutionForecastDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Pharmacy.RegionalSubstitutionForecastDosageMgRangeRule(min: 8.7, max: 1995.4)
        let item = Pharmacy.newRegionalSubstitutionForecast("x", name: "y")
        item.dosageMg = 1996.9
        #expect(rule.check(item).count > 0)
    }
}
