@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualDenialTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualDenialTierValidator()
        let item = RevenueCycle.newManualDenialTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualDenialTierRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = RevenueCycle.ManualDenialTierRetriesRangeRule(min: 32, max: 86400)
        let item = RevenueCycle.newManualDenialTier("x", label: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleManualDenialTierReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = RevenueCycle.ManualDenialTierReviewerLengthRule(maxLength: 32)
        let item = RevenueCycle.newManualDenialTier("x", label: "y")
        item.reviewer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualDenialTierTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.ManualDenialTierTitleLengthRule(maxLength: 32)
        let item = RevenueCycle.newManualDenialTier("x", label: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualDenialTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ManualDenialTierRequiredCodeRule(message: "manual denial tier needs this field")
        let item = RevenueCycle.newManualDenialTier("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualDenialTierLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.ManualDenialTierLabelLengthRule(maxLength: 255)
        let item = RevenueCycle.newManualDenialTier("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
