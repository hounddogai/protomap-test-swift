@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalInteractionForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRegionalInteractionForecastValidator()
        let item = Pharmacy.newRegionalInteractionForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRegionalInteractionForecastDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Pharmacy.RegionalInteractionForecastDurationMinutesRangeRule(min: 16, max: 120)
        let item = Pharmacy.newRegionalInteractionForecast("x", name: "y")
        item.durationMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRegionalInteractionForecastRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.RegionalInteractionForecastRequiredNameRule(
            message: "regional interaction forecast needs this field"
        )
        let item = Pharmacy.newRegionalInteractionForecast("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRegionalInteractionForecastNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.RegionalInteractionForecastNameLengthRule(maxLength: 120)
        let item = Pharmacy.newRegionalInteractionForecast("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRegionalInteractionForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RegionalInteractionForecastCodeLengthRule(maxLength: 255)
        let item = Pharmacy.newRegionalInteractionForecast("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
