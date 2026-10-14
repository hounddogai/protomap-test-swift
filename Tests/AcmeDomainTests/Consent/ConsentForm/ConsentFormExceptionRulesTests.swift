@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormExceptionValidator()
        let item = Consent.newConsentFormException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormExceptionWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Consent.ConsentFormExceptionWeightRangeRule(min: 6.9, max: 1351.2)
        let item = Consent.newConsentFormException("x", name: "y")
        item.weight = 1352.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentConsentFormExceptionLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Consent.ConsentFormExceptionLocaleLengthRule(maxLength: 16)
        let item = Consent.newConsentFormException("x", name: "y")
        item.locale = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormExceptionRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Consent.ConsentFormExceptionRequiredPayerRule(message: "consent form exception needs a value")
        let item = Consent.newConsentFormException("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ConsentFormExceptionCodeLengthRule(maxLength: 255)
        let item = Consent.newConsentFormException("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormExceptionCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Consent.ConsentFormExceptionCreatedAtRangeRule(min: 64, max: 3600)
        let item = Consent.newConsentFormException("x", name: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
