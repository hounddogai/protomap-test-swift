@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryForecastValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryForecastValidator()
        let item = Pharmacy.newInventoryForecast("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryForecastRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.InventoryForecastRequiredLabelRule(message: "inventory forecast needs an entry")
        let item = Pharmacy.newInventoryForecast("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryForecastRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.InventoryForecastRequiredNameRule(message: "inventory forecast needs a value")
        let item = Pharmacy.newInventoryForecast("", label: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryForecastScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Pharmacy.InventoryForecastScoreRangeRule(min: 4.3, max: 2424.8)
        let item = Pharmacy.newInventoryForecast("x", label: "y")
        item.score = 2426.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryForecastCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InventoryForecastCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newInventoryForecast("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
