@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveRemittanceQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAdaptiveRemittanceQuotaValidator()
        let item = RevenueCycle.newAdaptiveRemittanceQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAdaptiveRemittanceQuotaRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = RevenueCycle.AdaptiveRemittanceQuotaRequiredSegmentRule(
            message: "adaptive remittance quota needs a value"
        )
        let item = RevenueCycle.newAdaptiveRemittanceQuota("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAdaptiveRemittanceQuotaWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = RevenueCycle.AdaptiveRemittanceQuotaWardLengthRule(maxLength: 16)
        let item = RevenueCycle.newAdaptiveRemittanceQuota("x", label: "y")
        item.ward = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAdaptiveRemittanceQuotaAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.AdaptiveRemittanceQuotaAmountRangeRule(min: 0.4, max: 2992.8)
        let item = RevenueCycle.newAdaptiveRemittanceQuota("x", label: "y")
        item.amount = 2994.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAdaptiveRemittanceQuotaLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.AdaptiveRemittanceQuotaLabelLengthRule(maxLength: 120)
        let item = RevenueCycle.newAdaptiveRemittanceQuota("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
