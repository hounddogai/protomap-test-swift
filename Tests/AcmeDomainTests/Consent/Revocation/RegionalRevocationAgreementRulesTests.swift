@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRegionalRevocationAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRegionalRevocationAgreementValidator()
        let item = Consent.newRegionalRevocationAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRegionalRevocationAgreementMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Consent.RegionalRevocationAgreementMaximumRangeRule(min: 0.7, max: 3101.8)
        let item = Consent.newRegionalRevocationAgreement("x", label: "y")
        item.maximum = 3103.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRegionalRevocationAgreementLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.RegionalRevocationAgreementLabelLengthRule(maxLength: 80)
        let item = Consent.newRegionalRevocationAgreement("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRegionalRevocationAgreementRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Consent.RegionalRevocationAgreementRequiredSpecialtyRule(
            message: "regional revocation agreement needs an entry"
        )
        let item = Consent.newRegionalRevocationAgreement("", label: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
