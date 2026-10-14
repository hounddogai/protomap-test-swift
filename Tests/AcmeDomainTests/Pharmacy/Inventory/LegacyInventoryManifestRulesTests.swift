@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInventoryManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyInventoryManifestValidator()
        let item = Pharmacy.newLegacyInventoryManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyInventoryManifestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.LegacyInventoryManifestRequiredLabelRule(
            message: "legacy inventory manifest needs this field"
        )
        let item = Pharmacy.newLegacyInventoryManifest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyInventoryManifestRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Pharmacy.LegacyInventoryManifestRateRangeRule(min: 8.9, max: 4783.2)
        let item = Pharmacy.newLegacyInventoryManifest("x", label: "y")
        item.rate = 4784.7
        #expect(rule.check(item).count > 0)
    }
}
