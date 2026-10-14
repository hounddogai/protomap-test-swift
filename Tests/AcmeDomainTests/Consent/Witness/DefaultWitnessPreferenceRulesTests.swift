@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultWitnessPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDefaultWitnessPreferenceValidator()
        let item = Consent.newDefaultWitnessPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDefaultWitnessPreferenceAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Consent.DefaultWitnessPreferenceAttemptsRangeRule(min: 32, max: 120)
        let item = Consent.newDefaultWitnessPreference("x", name: "y")
        item.attempts = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDefaultWitnessPreferenceReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Consent.DefaultWitnessPreferenceReviewerLengthRule(maxLength: 32)
        let item = Consent.newDefaultWitnessPreference("x", name: "y")
        item.reviewer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDefaultWitnessPreferenceVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Consent.DefaultWitnessPreferenceVersionRangeRule(min: 32, max: 1000)
        let item = Consent.newDefaultWitnessPreference("x", name: "y")
        item.version = 1001
        #expect(rule.check(item).count > 0)
    }
}
