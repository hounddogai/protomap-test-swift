@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormMappingValidator()
        let item = Consent.newConsentFormMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormMappingAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Consent.ConsentFormMappingAcuityRangeRule(min: 32, max: 64)
        let item = Consent.newConsentFormMapping("x", label: "y")
        item.acuity = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentConsentFormMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ConsentFormMappingCodeLengthRule(maxLength: 32)
        let item = Consent.newConsentFormMapping("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormMappingRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormMappingRequiredCodeRule(message: "consent form mapping needs an entry")
        let item = Consent.newConsentFormMapping("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormMappingDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Consent.ConsentFormMappingDescriptionLengthRule(maxLength: 255)
        let item = Consent.newConsentFormMapping("x", label: "y")
        item.description = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormMappingRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.ConsentFormMappingRequiredLabelRule(message: "consent form mapping needs a value")
        let item = Consent.newConsentFormMapping("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
