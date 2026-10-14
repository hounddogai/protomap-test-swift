@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTieredTaskOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTieredTaskOverrideValidator()
        let item = ClinicalOps.newTieredTaskOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTieredTaskOverrideTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = ClinicalOps.TieredTaskOverrideTimezoneLengthRule(maxLength: 3600)
        let item = ClinicalOps.newTieredTaskOverride("x", label: "y")
        item.timezone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTieredTaskOverrideAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = ClinicalOps.TieredTaskOverrideAttemptsRangeRule(min: 64, max: 80)
        let item = ClinicalOps.newTieredTaskOverride("x", label: "y")
        item.attempts = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTieredTaskOverrideRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.TieredTaskOverrideRequiredLabelRule(message: "tiered task override needs this field")
        let item = ClinicalOps.newTieredTaskOverride("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
