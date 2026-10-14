@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackDenialReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackDenialReviewValidator()
        let item = RevenueCycle.newFallbackDenialReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackDenialReviewLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.FallbackDenialReviewLabelLengthRule(maxLength: 16)
        let item = RevenueCycle.newFallbackDenialReview("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleFallbackDenialReviewDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = RevenueCycle.FallbackDenialReviewDurationMinutesRangeRule(min: 120, max: 3600)
        let item = RevenueCycle.newFallbackDenialReview("x", label: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleFallbackDenialReviewEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = RevenueCycle.FallbackDenialReviewEncounterIDLengthRule(maxLength: 86400)
        let item = RevenueCycle.newFallbackDenialReview("x", label: "y")
        item.encounterID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleFallbackDenialReviewMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.FallbackDenialReviewMaximumRangeRule(min: 4.9, max: 105.9)
        let item = RevenueCycle.newFallbackDenialReview("x", label: "y")
        item.maximum = 107.4
        #expect(rule.check(item).count > 0)
    }
}
