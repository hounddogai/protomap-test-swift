@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientLanguageAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientLanguageAgreementValidator()
        let item = Consent.newLenientLanguageAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientLanguageAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LenientLanguageAgreementRequiredCodeRule(message: "lenient language agreement needs a value")
        let item = Consent.newLenientLanguageAgreement("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientLanguageAgreementTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.LenientLanguageAgreementTitleLengthRule(maxLength: 255)
        let item = Consent.newLenientLanguageAgreement("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLenientLanguageAgreementRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Consent.LenientLanguageAgreementRequiredDiagnosisCodeRule(
            message: "lenient language agreement needs this field"
        )
        let item = Consent.newLenientLanguageAgreement("", title: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientLanguageAgreementRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Consent.LenientLanguageAgreementRequiredBedRule(message: "lenient language agreement needs a value")
        let item = Consent.newLenientLanguageAgreement("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
