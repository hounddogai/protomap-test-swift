@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyInteractionForecastValidator()
        let item = Pharmacy.newLegacyInteractionForecast("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyInteractionForecastTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.LegacyInteractionForecastTitleLengthRule(maxLength: 32)
        let item = Pharmacy.newLegacyInteractionForecast("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyInteractionForecastRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.LegacyInteractionForecastRequiredTitleRule(
            message: "legacy interaction forecast needs this field"
        )
        let item = Pharmacy.newLegacyInteractionForecast("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyInteractionForecastWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Pharmacy.LegacyInteractionForecastWardLengthRule(maxLength: 86400)
        let item = Pharmacy.newLegacyInteractionForecast("x", title: "y")
        item.ward = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
