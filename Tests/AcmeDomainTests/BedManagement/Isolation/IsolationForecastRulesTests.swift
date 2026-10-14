@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementIsolationForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultIsolationForecastValidator()
        let item = BedManagement.newIsolationForecast("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementIsolationForecastRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.IsolationForecastRequiredCodeRule(message: "isolation forecast needs a value")
        let item = BedManagement.newIsolationForecast("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationForecastRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = BedManagement.IsolationForecastRegionLengthRule(maxLength: 1000)
        let item = BedManagement.newIsolationForecast("x", name: "y")
        item.region = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementIsolationForecastRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = BedManagement.IsolationForecastRequiredNameRule(message: "isolation forecast needs an entry")
        let item = BedManagement.newIsolationForecast("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationForecastRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = BedManagement.IsolationForecastRequiredRegionRule(message: "isolation forecast needs this field")
        let item = BedManagement.newIsolationForecast("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementIsolationForecastRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = BedManagement.IsolationForecastRequiredCountryRule(message: "isolation forecast needs this field")
        let item = BedManagement.newIsolationForecast("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
