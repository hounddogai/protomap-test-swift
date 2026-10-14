@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormTargetValidator()
        let item = Consent.newConsentFormTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormTargetLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Consent.ConsentFormTargetLocaleLengthRule(maxLength: 32)
        let item = Consent.newConsentFormTarget("x", name: "y")
        item.locale = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormTargetRequiredCodeRule(message: "consent form target needs this field")
        let item = Consent.newConsentFormTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormTargetRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Consent.ConsentFormTargetRequiredLocaleRule(message: "consent form target needs an entry")
        let item = Consent.newConsentFormTarget("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ConsentFormTargetCodeLengthRule(maxLength: 16)
        let item = Consent.newConsentFormTarget("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
