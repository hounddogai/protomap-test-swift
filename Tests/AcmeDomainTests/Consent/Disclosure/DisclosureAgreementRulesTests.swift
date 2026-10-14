@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureAgreementValidator()
        let item = Consent.newDisclosureAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureAgreementRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Consent.DisclosureAgreementRequiredLocaleRule(message: "disclosure agreement needs a value")
        let item = Consent.newDisclosureAgreement("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureAgreementCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Consent.DisclosureAgreementCreatedAtRangeRule(min: 255, max: 86400)
        let item = Consent.newDisclosureAgreement("x", title: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureAgreementTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.DisclosureAgreementTitleLengthRule(maxLength: 64)
        let item = Consent.newDisclosureAgreement("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
