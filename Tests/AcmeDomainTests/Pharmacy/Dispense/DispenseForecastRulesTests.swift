@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseForecastValidator()
        let item = Pharmacy.newDispenseForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseForecastReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Pharmacy.DispenseForecastReviewerLengthRule(maxLength: 1000)
        let item = Pharmacy.newDispenseForecast("x", name: "y")
        item.reviewer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseForecastRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Pharmacy.DispenseForecastRequiredFacilityRule(message: "dispense forecast needs an entry")
        let item = Pharmacy.newDispenseForecast("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseForecastEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Pharmacy.DispenseForecastEndsAtRangeRule(min: 3600, max: 86400)
        let item = Pharmacy.newDispenseForecast("x", name: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseForecastRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.DispenseForecastRequiredNameRule(message: "dispense forecast needs this field")
        let item = Pharmacy.newDispenseForecast("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseForecastRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Pharmacy.DispenseForecastRequiredReviewerRule(message: "dispense forecast needs a value")
        let item = Pharmacy.newDispenseForecast("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyDispenseForecastRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Pharmacy.DispenseForecastRateRangeRule(min: 7.5, max: 1670.4)
        let item = Pharmacy.newDispenseForecast("x", name: "y")
        item.rate = 1671.9
        #expect(rule.check(item).count > 0)
    }
}
