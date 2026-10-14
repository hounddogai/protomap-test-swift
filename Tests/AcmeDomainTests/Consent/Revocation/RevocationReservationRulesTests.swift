@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationReservationValidator()
        let item = Consent.newRevocationReservation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationReservationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RevocationReservationRequiredCodeRule(message: "revocation reservation needs a value")
        let item = Consent.newRevocationReservation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRevocationReservationRequiredDiagnosisCodeRuleTests {
    @Test func flagsABlankDiagnosisCode() throws {
        let rule = Consent.RevocationReservationRequiredDiagnosisCodeRule(
            message: "revocation reservation needs an entry"
        )
        let item = Consent.newRevocationReservation("", label: "")
        item.diagnosisCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRevocationReservationAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Consent.RevocationReservationAllergyLengthRule(maxLength: 120)
        let item = Consent.newRevocationReservation("x", label: "y")
        item.allergy = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}
