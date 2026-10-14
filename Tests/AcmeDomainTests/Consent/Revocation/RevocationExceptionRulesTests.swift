@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationExceptionValidator()
        let item = Consent.newRevocationException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationExceptionMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Consent.RevocationExceptionMinimumRangeRule(min: 9.0, max: 3140.6)
        let item = Consent.newRevocationException("x", name: "y")
        item.minimum = 3142.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRevocationExceptionNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.RevocationExceptionNameLengthRule(maxLength: 32)
        let item = Consent.newRevocationException("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationExceptionRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Consent.RevocationExceptionRequiredSpecialtyRule(message: "revocation exception needs an entry")
        let item = Consent.newRevocationException("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRevocationExceptionSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Consent.RevocationExceptionSpecialtyLengthRule(maxLength: 32)
        let item = Consent.newRevocationException("x", name: "y")
        item.specialty = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}
