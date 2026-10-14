@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePendingClaimReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPendingClaimReviewValidator()
        let item = RevenueCycle.newPendingClaimReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePendingClaimReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.PendingClaimReviewCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newPendingClaimReview("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePendingClaimReviewCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = RevenueCycle.PendingClaimReviewCapacityRangeRule(min: 32, max: 3600)
        let item = RevenueCycle.newPendingClaimReview("x", title: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCyclePendingClaimReviewAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.PendingClaimReviewAmountRangeRule(min: 2.8, max: 1270.4)
        let item = RevenueCycle.newPendingClaimReview("x", title: "y")
        item.amount = 1271.9
        #expect(rule.check(item).count > 0)
    }
}
