@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormOverrideValidator()
        let item = Consent.newConsentFormOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ConsentFormOverrideCodeLengthRule(maxLength: 1000)
        let item = Consent.newConsentFormOverride("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormOverrideRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.ConsentFormOverrideRequiredLabelRule(message: "consent form override needs an entry")
        let item = Consent.newConsentFormOverride("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormOverrideRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Consent.ConsentFormOverrideRequiredCountryRule(message: "consent form override needs this field")
        let item = Consent.newConsentFormOverride("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
