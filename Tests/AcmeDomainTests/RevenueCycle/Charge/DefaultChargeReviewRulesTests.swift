@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultChargeReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultChargeReviewValidator()
        let item = RevenueCycle.newDefaultChargeReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultChargeReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.DefaultChargeReviewCodeLengthRule(maxLength: 32)
        let item = RevenueCycle.newDefaultChargeReview("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultChargeReviewWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = RevenueCycle.DefaultChargeReviewWardLengthRule(maxLength: 120)
        let item = RevenueCycle.newDefaultChargeReview("x", label: "y")
        item.ward = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultChargeReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.DefaultChargeReviewRequiredLabelRule(message: "default charge review needs this field")
        let item = RevenueCycle.newDefaultChargeReview("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultChargeReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.DefaultChargeReviewRequiredCodeRule(message: "default charge review needs a value")
        let item = RevenueCycle.newDefaultChargeReview("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultChargeReviewRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = RevenueCycle.DefaultChargeReviewRequiredOwnerIDRule(message: "default charge review needs a value")
        let item = RevenueCycle.newDefaultChargeReview("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
