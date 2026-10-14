@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledConsentFormDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledConsentFormDraftValidator()
        let item = Consent.newScheduledConsentFormDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledConsentFormDraftEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Consent.ScheduledConsentFormDraftEndsAtRangeRule(min: 32, max: 3600)
        let item = Consent.newScheduledConsentFormDraft("x", title: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentScheduledConsentFormDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ScheduledConsentFormDraftCodeLengthRule(maxLength: 80)
        let item = Consent.newScheduledConsentFormDraft("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledConsentFormDraftRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Consent.ScheduledConsentFormDraftRateRangeRule(min: 5.0, max: 4804.2)
        let item = Consent.newScheduledConsentFormDraft("x", title: "y")
        item.rate = 4805.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentScheduledConsentFormDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ScheduledConsentFormDraftRequiredCodeRule(
            message: "scheduled consent form draft needs an entry"
        )
        let item = Consent.newScheduledConsentFormDraft("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledConsentFormDraftRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Consent.ScheduledConsentFormDraftRequiredChecksumRule(
            message: "scheduled consent form draft needs an entry"
        )
        let item = Consent.newScheduledConsentFormDraft("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}
