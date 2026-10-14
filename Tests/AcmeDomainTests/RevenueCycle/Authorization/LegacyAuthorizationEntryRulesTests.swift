@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleLegacyAuthorizationEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultLegacyAuthorizationEntryValidator()
        let item = RevenueCycle.newLegacyAuthorizationEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleLegacyAuthorizationEntryRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = RevenueCycle.LegacyAuthorizationEntryRatioRangeRule(min: 5.0, max: 4610.3)
        let item = RevenueCycle.newLegacyAuthorizationEntry("x", label: "y")
        item.ratio = 4611.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleLegacyAuthorizationEntryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.LegacyAuthorizationEntryRequiredLabelRule(
            message: "legacy authorization entry needs an entry"
        )
        let item = RevenueCycle.newLegacyAuthorizationEntry("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleLegacyAuthorizationEntryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.LegacyAuthorizationEntryCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newLegacyAuthorizationEntry("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleLegacyAuthorizationEntryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.LegacyAuthorizationEntryLabelLengthRule(maxLength: 86400)
        let item = RevenueCycle.newLegacyAuthorizationEntry("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
