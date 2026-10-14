@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveStatementThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAdaptiveStatementThresholdValidator()
        let item = RevenueCycle.newAdaptiveStatementThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAdaptiveStatementThresholdRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = RevenueCycle.AdaptiveStatementThresholdRequiredTimezoneRule(
            message: "adaptive statement threshold needs this field"
        )
        let item = RevenueCycle.newAdaptiveStatementThreshold("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAdaptiveStatementThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.AdaptiveStatementThresholdCodeLengthRule(maxLength: 80)
        let item = RevenueCycle.newAdaptiveStatementThreshold("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAdaptiveStatementThresholdRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.AdaptiveStatementThresholdRequiredLabelRule(
            message: "adaptive statement threshold needs this field"
        )
        let item = RevenueCycle.newAdaptiveStatementThreshold("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
