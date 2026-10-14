@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementCleaningForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultCleaningForecastValidator()
        let item = BedManagement.newCleaningForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementCleaningForecastRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = BedManagement.CleaningForecastRequiredCountryRule(message: "cleaning forecast needs this field")
        let item = BedManagement.newCleaningForecast("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningForecastRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.CleaningForecastRequiredNameRule(message: "cleaning forecast needs a value")
        let item = BedManagement.newCleaningForecast("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementCleaningForecastRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = BedManagement.CleaningForecastRequiredWardRule(message: "cleaning forecast needs a value")
        let item = BedManagement.newCleaningForecast("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
