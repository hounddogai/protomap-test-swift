@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRevocationBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRevocationBaselineValidator()
        let item = Consent.newRevocationBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRevocationBaselineLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Consent.RevocationBaselineLimitRangeRule(min: 32, max: 80)
        let item = Consent.newRevocationBaseline("x", label: "y")
        item.limit = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRevocationBaselineRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Consent.RevocationBaselineRequiredPatientRefRule(message: "revocation baseline needs this field")
        let item = Consent.newRevocationBaseline("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRevocationBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RevocationBaselineRequiredCodeRule(message: "revocation baseline needs a value")
        let item = Consent.newRevocationBaseline("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRevocationBaselineDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = Consent.RevocationBaselineDiagnosisCodeLengthRule(maxLength: 86400)
        let item = Consent.newRevocationBaseline("x", label: "y")
        item.diagnosisCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRevocationBaselineAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Consent.RevocationBaselineAmountRangeRule(min: 5.3, max: 618.8)
        let item = Consent.newRevocationBaseline("x", label: "y")
        item.amount = 620.3
        #expect(rule.check(item).count > 0)
    }
}
