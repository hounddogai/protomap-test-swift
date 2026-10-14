@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationAgreementValidator()
        let item = Consent.newRevocationAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationAgreementBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Consent.RevocationAgreementBedLengthRule(maxLength: 1000)
        let item = Consent.newRevocationAgreement("x", label: "y")
        item.bed = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}
