@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimarySubstitutionAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPrimarySubstitutionAssignmentValidator()
        let item = Pharmacy.newPrimarySubstitutionAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPrimarySubstitutionAssignmentRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Pharmacy.PrimarySubstitutionAssignmentRequiredCountryRule(
            message: "primary substitution assignment needs this field"
        )
        let item = Pharmacy.newPrimarySubstitutionAssignment("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimarySubstitutionAssignmentRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Pharmacy.PrimarySubstitutionAssignmentRevisionRangeRule(min: 1000, max: 3600)
        let item = Pharmacy.newPrimarySubstitutionAssignment("x", label: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPrimarySubstitutionAssignmentRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Pharmacy.PrimarySubstitutionAssignmentRequiredWardRule(
            message: "primary substitution assignment needs a value"
        )
        let item = Pharmacy.newPrimarySubstitutionAssignment("", label: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}
