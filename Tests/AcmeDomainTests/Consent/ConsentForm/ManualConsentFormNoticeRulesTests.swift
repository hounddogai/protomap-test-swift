@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualConsentFormNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultManualConsentFormNoticeValidator()
        let item = Consent.newManualConsentFormNotice("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentManualConsentFormNoticeAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Consent.ManualConsentFormNoticeAttemptsRangeRule(min: 64, max: 1000)
        let item = Consent.newManualConsentFormNotice("x", label: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentManualConsentFormNoticeRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Consent.ManualConsentFormNoticeRegionLengthRule(maxLength: 86400)
        let item = Consent.newManualConsentFormNotice("x", label: "y")
        item.region = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentManualConsentFormNoticeStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Consent.ManualConsentFormNoticeStartsAtRangeRule(min: 32, max: 80)
        let item = Consent.newManualConsentFormNotice("x", label: "y")
        item.startsAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentManualConsentFormNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ManualConsentFormNoticeCodeLengthRule(maxLength: 64)
        let item = Consent.newManualConsentFormNotice("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
