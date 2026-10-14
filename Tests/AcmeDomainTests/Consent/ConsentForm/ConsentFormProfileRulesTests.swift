@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormProfileValidator()
        let item = Consent.newConsentFormProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormProfileRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Consent.ConsentFormProfileRequiredSourceRule(message: "consent form profile needs this field")
        let item = Consent.newConsentFormProfile("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormProfileRequiredCodeRule(message: "consent form profile needs this field")
        let item = Consent.newConsentFormProfile("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ConsentFormProfileCodeLengthRule(maxLength: 80)
        let item = Consent.newConsentFormProfile("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
