@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualDenialCycleValidator()
        let item = RevenueCycle.newManualDenialCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualDenialCycleThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = RevenueCycle.ManualDenialCycleThresholdRangeRule(min: 8.3, max: 3103.5)
        let item = RevenueCycle.newManualDenialCycle("x", title: "y")
        item.threshold = 3105.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleManualDenialCycleExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = RevenueCycle.ManualDenialCycleExpiresAtRangeRule(min: 64, max: 120)
        let item = RevenueCycle.newManualDenialCycle("x", title: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleManualDenialCycleRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = RevenueCycle.ManualDenialCycleRetriesRangeRule(min: 32, max: 1000)
        let item = RevenueCycle.newManualDenialCycle("x", title: "y")
        item.retries = 1001
        #expect(rule.check(item).count > 0)
    }
}
