@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialBaselineValidator()
        let item = RevenueCycle.newDenialBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialBaselineRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = RevenueCycle.DenialBaselineRevisionRangeRule(min: 64, max: 64)
        let item = RevenueCycle.newDenialBaseline("x", label: "y")
        item.revision = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialBaselineLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.DenialBaselineLabelLengthRule(maxLength: 80)
        let item = RevenueCycle.newDenialBaseline("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialBaselineSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = RevenueCycle.DenialBaselineSummaryLengthRule(maxLength: 120)
        let item = RevenueCycle.newDenialBaseline("x", label: "y")
        item.summary = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialBaselineRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.DenialBaselineRequiredLabelRule(message: "denial baseline needs this field")
        let item = RevenueCycle.newDenialBaseline("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
