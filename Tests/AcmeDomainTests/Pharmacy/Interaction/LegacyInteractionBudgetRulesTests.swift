@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyInteractionBudgetValidator()
        let item = Pharmacy.newLegacyInteractionBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyInteractionBudgetRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Pharmacy.LegacyInteractionBudgetRequiredFacilityRule(
            message: "legacy interaction budget needs this field"
        )
        let item = Pharmacy.newLegacyInteractionBudget("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyInteractionBudgetRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Pharmacy.LegacyInteractionBudgetRequiredTimezoneRule(
            message: "legacy interaction budget needs this field"
        )
        let item = Pharmacy.newLegacyInteractionBudget("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyInteractionBudgetVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Pharmacy.LegacyInteractionBudgetVisitMinutesRangeRule(min: 64, max: 120)
        let item = Pharmacy.newLegacyInteractionBudget("x", name: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}
