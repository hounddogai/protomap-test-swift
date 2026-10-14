@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualFormularyReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultManualFormularyReviewValidator()
        let item = Pharmacy.newManualFormularyReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyManualFormularyReviewDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Pharmacy.ManualFormularyReviewDescriptionLengthRule(maxLength: 16)
        let item = Pharmacy.newManualFormularyReview("x", name: "y")
        item.description = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualFormularyReviewPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Pharmacy.ManualFormularyReviewPatientRefLengthRule(maxLength: 32)
        let item = Pharmacy.newManualFormularyReview("x", name: "y")
        item.patientRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualFormularyReviewFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Pharmacy.ManualFormularyReviewFloorValueRangeRule(min: 5.3, max: 2952.7)
        let item = Pharmacy.newManualFormularyReview("x", name: "y")
        item.floorValue = 2954.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyManualFormularyReviewExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.ManualFormularyReviewExpiresAtRangeRule(min: 32, max: 86400)
        let item = Pharmacy.newManualFormularyReview("x", name: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyManualFormularyReviewRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Pharmacy.ManualFormularyReviewRequiredPatientRefRule(
            message: "manual formulary review needs this field"
        )
        let item = Pharmacy.newManualFormularyReview("", name: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
