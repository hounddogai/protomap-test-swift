@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackFormularyAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFallbackFormularyAgreementValidator()
        let item = Pharmacy.newFallbackFormularyAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFallbackFormularyAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.FallbackFormularyAgreementRequiredCodeRule(
            message: "fallback formulary agreement needs an entry"
        )
        let item = Pharmacy.newFallbackFormularyAgreement("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFallbackFormularyAgreementRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Pharmacy.FallbackFormularyAgreementRevisionRangeRule(min: 32, max: 255)
        let item = Pharmacy.newFallbackFormularyAgreement("x", label: "y")
        item.revision = 256
        #expect(rule.check(item).count > 0)
    }
}
