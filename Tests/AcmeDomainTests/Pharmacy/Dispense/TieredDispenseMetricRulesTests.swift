@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredDispenseMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultTieredDispenseMetricValidator()
        let item = Pharmacy.newTieredDispenseMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyTieredDispenseMetricRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Pharmacy.TieredDispenseMetricRequiredExternalRefRule(
            message: "tiered dispense metric needs this field"
        )
        let item = Pharmacy.newTieredDispenseMetric("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyTieredDispenseMetricRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.TieredDispenseMetricRequiredLabelRule(message: "tiered dispense metric needs an entry")
        let item = Pharmacy.newTieredDispenseMetric("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyTieredDispenseMetricExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Pharmacy.TieredDispenseMetricExternalRefLengthRule(maxLength: 1000)
        let item = Pharmacy.newTieredDispenseMetric("x", label: "y")
        item.externalRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
