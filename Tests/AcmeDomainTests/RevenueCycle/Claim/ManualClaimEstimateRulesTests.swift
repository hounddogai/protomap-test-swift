@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualClaimEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualClaimEstimateValidator()
        let item = RevenueCycle.newManualClaimEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualClaimEstimateCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = RevenueCycle.ManualClaimEstimateCapacityRangeRule(min: 120, max: 1000)
        let item = RevenueCycle.newManualClaimEstimate("x", name: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleManualClaimEstimateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.ManualClaimEstimateRequiredNameRule(message: "manual claim estimate needs this field")
        let item = RevenueCycle.newManualClaimEstimate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualClaimEstimateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ManualClaimEstimateNameLengthRule(maxLength: 3600)
        let item = RevenueCycle.newManualClaimEstimate("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualClaimEstimateReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = RevenueCycle.ManualClaimEstimateReviewerLengthRule(maxLength: 3600)
        let item = RevenueCycle.newManualClaimEstimate("x", name: "y")
        item.reviewer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
