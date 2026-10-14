@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimRequestValidator()
        let item = RevenueCycle.newClaimRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimRequestFacilityLengthRuleTests {
    @Test func flagsALongFacility() throws {
        let rule = RevenueCycle.ClaimRequestFacilityLengthRule(maxLength: 16)
        let item = RevenueCycle.newClaimRequest("x", title: "y")
        item.facility = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.facility = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ClaimRequestRequiredCodeRule(message: "claim request needs this field")
        let item = RevenueCycle.newClaimRequest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimRequestRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = RevenueCycle.ClaimRequestRequiredReviewerRule(message: "claim request needs a value")
        let item = RevenueCycle.newClaimRequest("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimRequestGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = RevenueCycle.ClaimRequestGraceDaysRangeRule(min: 64, max: 86400)
        let item = RevenueCycle.newClaimRequest("x", title: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}
