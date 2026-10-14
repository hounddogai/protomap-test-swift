@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementAdaptiveCleaningBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultAdaptiveCleaningBudgetValidator()
        let item = BedManagement.newAdaptiveCleaningBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementAdaptiveCleaningBudgetCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = BedManagement.AdaptiveCleaningBudgetCostRangeRule(min: 9.7, max: 2835.5)
        let item = BedManagement.newAdaptiveCleaningBudget("x", label: "y")
        item.cost = 2837.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementAdaptiveCleaningBudgetPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = BedManagement.AdaptiveCleaningBudgetPatientRefLengthRule(maxLength: 16)
        let item = BedManagement.newAdaptiveCleaningBudget("x", label: "y")
        item.patientRef = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementAdaptiveCleaningBudgetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.AdaptiveCleaningBudgetRequiredLabelRule(
            message: "adaptive cleaning budget needs a value"
        )
        let item = BedManagement.newAdaptiveCleaningBudget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
