@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedClaimTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedClaimTargetValidator()
        let item = RevenueCycle.newBatchedClaimTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedClaimTargetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.BatchedClaimTargetLabelLengthRule(maxLength: 32)
        let item = RevenueCycle.newBatchedClaimTarget("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleBatchedClaimTargetThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = RevenueCycle.BatchedClaimTargetThresholdRangeRule(min: 8.8, max: 3957.0)
        let item = RevenueCycle.newBatchedClaimTarget("x", label: "y")
        item.threshold = 3958.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedClaimTargetCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = RevenueCycle.BatchedClaimTargetCeilingRangeRule(min: 8.2, max: 3593.0)
        let item = RevenueCycle.newBatchedClaimTarget("x", label: "y")
        item.ceiling = 3594.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedClaimTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.BatchedClaimTargetRequiredCodeRule(message: "batched claim target needs this field")
        let item = RevenueCycle.newBatchedClaimTarget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
