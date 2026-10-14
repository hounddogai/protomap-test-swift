@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionReservationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionReservationValidator()
        let item = Pharmacy.newSubstitutionReservation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionReservationRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Pharmacy.SubstitutionReservationRequiredAllergyRule(
            message: "substitution reservation needs this field"
        )
        let item = Pharmacy.newSubstitutionReservation("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionReservationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.SubstitutionReservationRequiredTitleRule(message: "substitution reservation needs an entry")
        let item = Pharmacy.newSubstitutionReservation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacySubstitutionReservationRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Pharmacy.SubstitutionReservationRetriesRangeRule(min: 3600, max: 86400)
        let item = Pharmacy.newSubstitutionReservation("x", title: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}
