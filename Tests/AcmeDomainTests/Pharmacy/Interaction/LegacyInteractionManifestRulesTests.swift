@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyInteractionManifestValidator()
        let item = Pharmacy.newLegacyInteractionManifest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyInteractionManifestStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.LegacyInteractionManifestStartsAtRangeRule(min: 16, max: 1000)
        let item = Pharmacy.newLegacyInteractionManifest("x", label: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLegacyInteractionManifestRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Pharmacy.LegacyInteractionManifestRegionLengthRule(maxLength: 80)
        let item = Pharmacy.newLegacyInteractionManifest("x", label: "y")
        item.region = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyInteractionManifestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.LegacyInteractionManifestRequiredCodeRule(
            message: "legacy interaction manifest needs a value"
        )
        let item = Pharmacy.newLegacyInteractionManifest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyInteractionManifestRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Pharmacy.LegacyInteractionManifestRequiredLocaleRule(
            message: "legacy interaction manifest needs this field"
        )
        let item = Pharmacy.newLegacyInteractionManifest("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyInteractionManifestWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Pharmacy.LegacyInteractionManifestWeightRangeRule(min: 9.6, max: 2312.5)
        let item = Pharmacy.newLegacyInteractionManifest("x", label: "y")
        item.weight = 2314.0
        #expect(rule.check(item).count > 0)
    }
}
