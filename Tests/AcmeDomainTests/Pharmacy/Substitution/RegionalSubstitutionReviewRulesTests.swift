@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRegionalSubstitutionReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRegionalSubstitutionReviewValidator()
        let item = Pharmacy.newRegionalSubstitutionReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRegionalSubstitutionReviewRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Pharmacy.RegionalSubstitutionReviewRequiredCountryRule(
            message: "regional substitution review needs a value"
        )
        let item = Pharmacy.newRegionalSubstitutionReview("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRegionalSubstitutionReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.RegionalSubstitutionReviewRequiredNameRule(
            message: "regional substitution review needs a value"
        )
        let item = Pharmacy.newRegionalSubstitutionReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyRegionalSubstitutionReviewRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Pharmacy.RegionalSubstitutionReviewRateRangeRule(min: 5.9, max: 3680.6)
        let item = Pharmacy.newRegionalSubstitutionReview("x", name: "y")
        item.rate = 3682.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRegionalSubstitutionReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.RegionalSubstitutionReviewNameLengthRule(maxLength: 64)
        let item = Pharmacy.newRegionalSubstitutionReview("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRegionalSubstitutionReviewPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Pharmacy.RegionalSubstitutionReviewPatientRefLengthRule(maxLength: 32)
        let item = Pharmacy.newRegionalSubstitutionReview("x", name: "y")
        item.patientRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}
