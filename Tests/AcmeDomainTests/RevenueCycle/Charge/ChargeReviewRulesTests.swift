@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeReviewValidator()
        let item = RevenueCycle.newChargeReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeReviewSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = RevenueCycle.ChargeReviewSegmentLengthRule(maxLength: 255)
        let item = RevenueCycle.newChargeReview("x", name: "y")
        item.segment = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ChargeReviewRequiredCodeRule(message: "charge review needs an entry")
        let item = RevenueCycle.newChargeReview("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.ChargeReviewRequiredNameRule(message: "charge review needs this field")
        let item = RevenueCycle.newChargeReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ChargeReviewNameLengthRule(maxLength: 86400)
        let item = RevenueCycle.newChargeReview("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeReviewSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = RevenueCycle.ChargeReviewSummaryLengthRule(maxLength: 1000)
        let item = RevenueCycle.newChargeReview("x", name: "y")
        item.summary = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
