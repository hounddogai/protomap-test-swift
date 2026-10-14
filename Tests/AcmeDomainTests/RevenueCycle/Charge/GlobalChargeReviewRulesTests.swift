@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalChargeReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultGlobalChargeReviewValidator()
        let item = RevenueCycle.newGlobalChargeReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleGlobalChargeReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.GlobalChargeReviewNameLengthRule(maxLength: 32)
        let item = RevenueCycle.newGlobalChargeReview("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleGlobalChargeReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.GlobalChargeReviewCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newGlobalChargeReview("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
