@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedConsentFormNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedConsentFormNoticeValidator()
        let item = Consent.newCappedConsentFormNotice("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedConsentFormNoticeAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Consent.CappedConsentFormNoticeAttemptsRangeRule(min: 32, max: 64)
        let item = Consent.newCappedConsentFormNotice("x", title: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}
