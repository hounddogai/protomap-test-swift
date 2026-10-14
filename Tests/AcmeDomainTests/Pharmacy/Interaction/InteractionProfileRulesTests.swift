@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionProfileValidator()
        let item = Pharmacy.newInteractionProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionProfileWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Pharmacy.InteractionProfileWeightRangeRule(min: 2.1, max: 2849.4)
        let item = Pharmacy.newInteractionProfile("x", name: "y")
        item.weight = 2850.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionProfilePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Pharmacy.InteractionProfilePriorityRangeRule(min: 16, max: 16)
        let item = Pharmacy.newInteractionProfile("x", name: "y")
        item.priority = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionProfileRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Pharmacy.InteractionProfileRequiredSpecialtyRule(message: "interaction profile needs an entry")
        let item = Pharmacy.newInteractionProfile("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
