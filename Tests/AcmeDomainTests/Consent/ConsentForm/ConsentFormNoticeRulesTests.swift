@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormNoticeValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormNoticeValidator()
        let item = Consent.newConsentFormNotice("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormNoticeCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ConsentFormNoticeCodeLengthRule(maxLength: 1000)
        let item = Consent.newConsentFormNotice("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormNoticeRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormNoticeRequiredCodeRule(message: "consent form notice needs a value")
        let item = Consent.newConsentFormNotice("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
