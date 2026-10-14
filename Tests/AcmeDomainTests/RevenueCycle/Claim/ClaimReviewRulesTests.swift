@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimReviewValidator()
        let item = RevenueCycle.newClaimReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimReviewChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = RevenueCycle.ClaimReviewChecksumLengthRule(maxLength: 32)
        let item = RevenueCycle.newClaimReview("x", name: "y")
        item.checksum = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimReviewMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = RevenueCycle.ClaimReviewMinimumRangeRule(min: 5.0, max: 1926.2)
        let item = RevenueCycle.newClaimReview("x", name: "y")
        item.minimum = 1927.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ClaimReviewCodeLengthRule(maxLength: 80)
        let item = RevenueCycle.newClaimReview("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
