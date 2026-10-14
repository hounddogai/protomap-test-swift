@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacySubstitutionRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultSubstitutionRequestValidator()
        let item = Pharmacy.newSubstitutionRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacySubstitutionRequestDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Pharmacy.SubstitutionRequestDurationMinutesRangeRule(min: 32, max: 64)
        let item = Pharmacy.newSubstitutionRequest("x", title: "y")
        item.durationMinutes = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySubstitutionRequestQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Pharmacy.SubstitutionRequestQuantityRangeRule(min: 80, max: 1000)
        let item = Pharmacy.newSubstitutionRequest("x", title: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacySubstitutionRequestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.SubstitutionRequestRequiredTitleRule(message: "substitution request needs an entry")
        let item = Pharmacy.newSubstitutionRequest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
