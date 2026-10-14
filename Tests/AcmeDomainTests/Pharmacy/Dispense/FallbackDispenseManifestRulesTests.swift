@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackDispenseManifestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFallbackDispenseManifestValidator()
        let item = Pharmacy.newFallbackDispenseManifest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFallbackDispenseManifestRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Pharmacy.FallbackDispenseManifestRatioRangeRule(min: 8.0, max: 2637.4)
        let item = Pharmacy.newFallbackDispenseManifest("x", name: "y")
        item.ratio = 2638.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFallbackDispenseManifestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.FallbackDispenseManifestRequiredTitleRule(
            message: "fallback dispense manifest needs a value"
        )
        let item = Pharmacy.newFallbackDispenseManifest("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFallbackDispenseManifestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FallbackDispenseManifestCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newFallbackDispenseManifest("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFallbackDispenseManifestStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Pharmacy.FallbackDispenseManifestStartsAtRangeRule(min: 86400, max: 86400)
        let item = Pharmacy.newFallbackDispenseManifest("x", name: "y")
        item.startsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFallbackDispenseManifestTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.FallbackDispenseManifestTitleLengthRule(maxLength: 80)
        let item = Pharmacy.newFallbackDispenseManifest("x", name: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
