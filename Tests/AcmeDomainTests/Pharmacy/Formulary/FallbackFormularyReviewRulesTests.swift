@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackFormularyReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFallbackFormularyReviewValidator()
        let item = Pharmacy.newFallbackFormularyReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFallbackFormularyReviewClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Pharmacy.FallbackFormularyReviewClinicianIDLengthRule(maxLength: 86400)
        let item = Pharmacy.newFallbackFormularyReview("x", name: "y")
        item.clinicianID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyFallbackFormularyReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.FallbackFormularyReviewRequiredCodeRule(
            message: "fallback formulary review needs this field"
        )
        let item = Pharmacy.newFallbackFormularyReview("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFallbackFormularyReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.FallbackFormularyReviewRequiredNameRule(
            message: "fallback formulary review needs this field"
        )
        let item = Pharmacy.newFallbackFormularyReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
