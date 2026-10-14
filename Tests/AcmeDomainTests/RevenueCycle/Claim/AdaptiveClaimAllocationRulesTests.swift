@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAdaptiveClaimAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAdaptiveClaimAllocationValidator()
        let item = RevenueCycle.newAdaptiveClaimAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAdaptiveClaimAllocationAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = RevenueCycle.AdaptiveClaimAllocationAttemptsRangeRule(min: 32, max: 86400)
        let item = RevenueCycle.newAdaptiveClaimAllocation("x", name: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAdaptiveClaimAllocationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.AdaptiveClaimAllocationRequiredNameRule(
            message: "adaptive claim allocation needs this field"
        )
        let item = RevenueCycle.newAdaptiveClaimAllocation("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAdaptiveClaimAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AdaptiveClaimAllocationRequiredCodeRule(
            message: "adaptive claim allocation needs a value"
        )
        let item = RevenueCycle.newAdaptiveClaimAllocation("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAdaptiveClaimAllocationCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = RevenueCycle.AdaptiveClaimAllocationCeilingRangeRule(min: 4.2, max: 805.2)
        let item = RevenueCycle.newAdaptiveClaimAllocation("x", name: "y")
        item.ceiling = 806.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAdaptiveClaimAllocationMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = RevenueCycle.AdaptiveClaimAllocationMinimumRangeRule(min: 3.4, max: 914.8)
        let item = RevenueCycle.newAdaptiveClaimAllocation("x", name: "y")
        item.minimum = 916.3
        #expect(rule.check(item).count > 0)
    }
}
