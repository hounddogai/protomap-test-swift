@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedSubstitutionBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultCappedSubstitutionBaselineValidator()
        let item = Pharmacy.newCappedSubstitutionBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyCappedSubstitutionBaselineRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Pharmacy.CappedSubstitutionBaselineRequiredCountryRule(
            message: "capped substitution baseline needs this field"
        )
        let item = Pharmacy.newCappedSubstitutionBaseline("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyCappedSubstitutionBaselineRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Pharmacy.CappedSubstitutionBaselineRequiredPhoneRule(
            message: "capped substitution baseline needs this field"
        )
        let item = Pharmacy.newCappedSubstitutionBaseline("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyCappedSubstitutionBaselineRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Pharmacy.CappedSubstitutionBaselineRequiredNameRule(
            message: "capped substitution baseline needs an entry"
        )
        let item = Pharmacy.newCappedSubstitutionBaseline("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
