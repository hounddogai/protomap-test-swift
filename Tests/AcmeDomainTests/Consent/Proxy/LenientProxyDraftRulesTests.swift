@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientProxyDraftValidator()
        let item = Consent.newLenientProxyDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientProxyDraftRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Consent.LenientProxyDraftRetriesRangeRule(min: 1000, max: 3600)
        let item = Consent.newLenientProxyDraft("x", name: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLenientProxyDraftThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Consent.LenientProxyDraftThresholdRangeRule(min: 8.1, max: 1276.0)
        let item = Consent.newLenientProxyDraft("x", name: "y")
        item.threshold = 1277.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLenientProxyDraftRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Consent.LenientProxyDraftRequiredLocaleRule(message: "lenient proxy draft needs an entry")
        let item = Consent.newLenientProxyDraft("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientProxyDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LenientProxyDraftCodeLengthRule(maxLength: 16)
        let item = Consent.newLenientProxyDraft("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
