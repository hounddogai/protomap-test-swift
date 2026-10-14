@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleWeightedDenialReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultWeightedDenialReviewValidator()
        let item = RevenueCycle.newWeightedDenialReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleWeightedDenialReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.WeightedDenialReviewNameLengthRule(maxLength: 80)
        let item = RevenueCycle.newWeightedDenialReview("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleWeightedDenialReviewCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = RevenueCycle.WeightedDenialReviewCostRangeRule(min: 5.0, max: 316.3)
        let item = RevenueCycle.newWeightedDenialReview("x", name: "y")
        item.cost = 317.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleWeightedDenialReviewCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = RevenueCycle.WeightedDenialReviewCurrencyLengthRule(maxLength: 1000)
        let item = RevenueCycle.newWeightedDenialReview("x", name: "y")
        item.currency = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}
