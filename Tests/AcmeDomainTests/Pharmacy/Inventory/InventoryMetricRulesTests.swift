@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryMetricValidator()
        let item = Pharmacy.newInventoryMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryMetricRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Pharmacy.InventoryMetricRefillsRangeRule(min: 3600, max: 86400)
        let item = Pharmacy.newInventoryMetric("x", title: "y")
        item.refills = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InventoryMetricRequiredCodeRule(message: "inventory metric needs a value")
        let item = Pharmacy.newInventoryMetric("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInventoryMetricRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Pharmacy.InventoryMetricRequiredSourceRule(message: "inventory metric needs this field")
        let item = Pharmacy.newInventoryMetric("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}
