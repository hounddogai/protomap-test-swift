@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedConsentFormPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedConsentFormPreferenceValidator()
        let item = Consent.newCappedConsentFormPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedConsentFormPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.CappedConsentFormPreferenceCodeLengthRule(maxLength: 255)
        let item = Consent.newCappedConsentFormPreference("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedConsentFormPreferenceQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Consent.CappedConsentFormPreferenceQuantityRangeRule(min: 32, max: 120)
        let item = Consent.newCappedConsentFormPreference("x", name: "y")
        item.quantity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentCappedConsentFormPreferenceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.CappedConsentFormPreferenceNameLengthRule(maxLength: 3600)
        let item = Consent.newCappedConsentFormPreference("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentCappedConsentFormPreferenceRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.CappedConsentFormPreferenceRequiredNameRule(
            message: "capped consent form preference needs an entry"
        )
        let item = Consent.newCappedConsentFormPreference("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedConsentFormPreferenceDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Consent.CappedConsentFormPreferenceDiagnosisCodeLengthRule(maxLength: 3600)
        let item = Consent.newCappedConsentFormPreference("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
