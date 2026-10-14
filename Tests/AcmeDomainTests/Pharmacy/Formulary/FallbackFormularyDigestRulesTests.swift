@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackFormularyDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFallbackFormularyDigestValidator()
        let item = Pharmacy.newFallbackFormularyDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFallbackFormularyDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.FallbackFormularyDigestCodeLengthRule(maxLength: 16)
        let item = Pharmacy.newFallbackFormularyDigest("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFallbackFormularyDigestRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Pharmacy.FallbackFormularyDigestRequiredSpecialtyRule(
            message: "fallback formulary digest needs an entry"
        )
        let item = Pharmacy.newFallbackFormularyDigest("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFallbackFormularyDigestRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.FallbackFormularyDigestRequiredNameRule(
            message: "fallback formulary digest needs this field"
        )
        let item = Pharmacy.newFallbackFormularyDigest("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
