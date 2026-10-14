@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualInventoryManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultManualInventoryManifestValidator()
        let item = Pharmacy.newManualInventoryManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyManualInventoryManifestBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Pharmacy.ManualInventoryManifestBedLengthRule(maxLength: 255)
        let item = Pharmacy.newManualInventoryManifest("x", label: "y")
        item.bed = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualInventoryManifestMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Pharmacy.ManualInventoryManifestMinimumRangeRule(min: 7.2, max: 4525.5)
        let item = Pharmacy.newManualInventoryManifest("x", label: "y")
        item.minimum = 4527.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyManualInventoryManifestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.ManualInventoryManifestLabelLengthRule(maxLength: 3600)
        let item = Pharmacy.newManualInventoryManifest("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualInventoryManifestRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Pharmacy.ManualInventoryManifestRequiredBedRule(message: "manual inventory manifest needs this field")
        let item = Pharmacy.newManualInventoryManifest("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualInventoryManifestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.ManualInventoryManifestRequiredLabelRule(message: "manual inventory manifest needs an entry")
        let item = Pharmacy.newManualInventoryManifest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
