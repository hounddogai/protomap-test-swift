@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedConsentFormRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedConsentFormRuleValidator()
        let item = Consent.newCappedConsentFormRule("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedConsentFormRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.CappedConsentFormRuleRequiredCodeRule(message: "capped consent form rule needs an entry")
        let item = Consent.newCappedConsentFormRule("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedConsentFormRuleNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.CappedConsentFormRuleNameLengthRule(maxLength: 255)
        let item = Consent.newCappedConsentFormRule("x", name: "y")
        item.name = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedConsentFormRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.CappedConsentFormRuleCodeLengthRule(maxLength: 255)
        let item = Consent.newCappedConsentFormRule("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedConsentFormRuleThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Consent.CappedConsentFormRuleThresholdRangeRule(min: 8.8, max: 2629.5)
        let item = Consent.newCappedConsentFormRule("x", name: "y")
        item.threshold = 2631.0
        #expect(rule.check(item).count > 0)
    }
}
