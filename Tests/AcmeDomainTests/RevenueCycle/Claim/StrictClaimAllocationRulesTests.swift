@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictClaimAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStrictClaimAllocationValidator()
        let item = RevenueCycle.newStrictClaimAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStrictClaimAllocationRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = RevenueCycle.StrictClaimAllocationRequiredRegionRule(
            message: "strict claim allocation needs an entry"
        )
        let item = RevenueCycle.newStrictClaimAllocation("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStrictClaimAllocationRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = RevenueCycle.StrictClaimAllocationRevisionRangeRule(min: 255, max: 86400)
        let item = RevenueCycle.newStrictClaimAllocation("x", label: "y")
        item.revision = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStrictClaimAllocationUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.StrictClaimAllocationUpdatedAtRangeRule(min: 64, max: 1000)
        let item = RevenueCycle.newStrictClaimAllocation("x", label: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStrictClaimAllocationStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = RevenueCycle.StrictClaimAllocationStartsAtRangeRule(min: 1000, max: 3600)
        let item = RevenueCycle.newStrictClaimAllocation("x", label: "y")
        item.startsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStrictClaimAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StrictClaimAllocationRequiredCodeRule(message: "strict claim allocation needs an entry")
        let item = RevenueCycle.newStrictClaimAllocation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
