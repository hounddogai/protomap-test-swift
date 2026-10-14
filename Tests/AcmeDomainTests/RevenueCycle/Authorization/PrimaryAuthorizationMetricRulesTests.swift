@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryAuthorizationMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPrimaryAuthorizationMetricValidator()
        let item = RevenueCycle.newPrimaryAuthorizationMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePrimaryAuthorizationMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.PrimaryAuthorizationMetricCodeLengthRule(maxLength: 32)
        let item = RevenueCycle.newPrimaryAuthorizationMetric("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePrimaryAuthorizationMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.PrimaryAuthorizationMetricRequiredCodeRule(
            message: "primary authorization metric needs a value"
        )
        let item = RevenueCycle.newPrimaryAuthorizationMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePrimaryAuthorizationMetricRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = RevenueCycle.PrimaryAuthorizationMetricRequiredReviewerRule(
            message: "primary authorization metric needs this field"
        )
        let item = RevenueCycle.newPrimaryAuthorizationMetric("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePrimaryAuthorizationMetricLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.PrimaryAuthorizationMetricLabelLengthRule(maxLength: 3600)
        let item = RevenueCycle.newPrimaryAuthorizationMetric("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePrimaryAuthorizationMetricBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = RevenueCycle.PrimaryAuthorizationMetricBatchSizeRangeRule(min: 80, max: 80)
        let item = RevenueCycle.newPrimaryAuthorizationMetric("x", label: "y")
        item.batchSize = 81
        #expect(rule.check(item).count > 0)
    }
}
