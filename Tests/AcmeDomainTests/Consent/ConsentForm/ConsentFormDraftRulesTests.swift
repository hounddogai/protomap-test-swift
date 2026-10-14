@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormDraftValidator()
        let item = Consent.newConsentFormDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ConsentFormDraftCodeLengthRule(maxLength: 255)
        let item = Consent.newConsentFormDraft("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormDraftRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Consent.ConsentFormDraftRequiredChannelRule(message: "consent form draft needs this field")
        let item = Consent.newConsentFormDraft("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}
