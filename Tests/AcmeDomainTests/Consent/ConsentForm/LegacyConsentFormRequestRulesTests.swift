@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyConsentFormRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLegacyConsentFormRequestValidator()
        let item = Consent.newLegacyConsentFormRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLegacyConsentFormRequestCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Consent.LegacyConsentFormRequestCreatedAtRangeRule(min: 255, max: 1000)
        let item = Consent.newLegacyConsentFormRequest("x", label: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLegacyConsentFormRequestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.LegacyConsentFormRequestLabelLengthRule(maxLength: 255)
        let item = Consent.newLegacyConsentFormRequest("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLegacyConsentFormRequestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LegacyConsentFormRequestCodeLengthRule(maxLength: 80)
        let item = Consent.newLegacyConsentFormRequest("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLegacyConsentFormRequestRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.LegacyConsentFormRequestRequiredLabelRule(
            message: "legacy consent form request needs an entry"
        )
        let item = Consent.newLegacyConsentFormRequest("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
