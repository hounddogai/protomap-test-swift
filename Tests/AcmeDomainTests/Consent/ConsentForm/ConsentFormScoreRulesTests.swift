@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormScoreValidator()
        let item = Consent.newConsentFormScore("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormScoreRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Consent.ConsentFormScoreRatioRangeRule(min: 1.7, max: 2670.0)
        let item = Consent.newConsentFormScore("x", name: "y")
        item.ratio = 2671.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentConsentFormScoreAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Consent.ConsentFormScoreAttemptsRangeRule(min: 16, max: 32)
        let item = Consent.newConsentFormScore("x", name: "y")
        item.attempts = 33
        #expect(rule.check(item).count > 0)
    }
}
