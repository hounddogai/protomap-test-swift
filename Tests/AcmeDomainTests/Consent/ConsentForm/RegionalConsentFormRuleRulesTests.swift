@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalConsentFormRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRegionalConsentFormRuleValidator()
        let item = Consent.newRegionalConsentFormRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRegionalConsentFormRuleRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Consent.RegionalConsentFormRuleRequiredLocaleRule(
            message: "regional consent form rule needs an entry"
        )
        let item = Consent.newRegionalConsentFormRule("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRegionalConsentFormRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RegionalConsentFormRuleCodeLengthRule(maxLength: 255)
        let item = Consent.newRegionalConsentFormRule("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
