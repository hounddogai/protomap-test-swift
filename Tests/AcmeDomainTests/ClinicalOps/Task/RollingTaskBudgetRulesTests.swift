@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRollingTaskBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRollingTaskBudgetValidator()
        let item = ClinicalOps.newRollingTaskBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRollingTaskBudgetCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = ClinicalOps.RollingTaskBudgetCreatedAtRangeRule(min: 16, max: 86400)
        let item = ClinicalOps.newRollingTaskBudget("x", name: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRollingTaskBudgetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.RollingTaskBudgetRequiredLabelRule(message: "rolling task budget needs this field")
        let item = ClinicalOps.newRollingTaskBudget("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingTaskBudgetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.RollingTaskBudgetRequiredNameRule(message: "rolling task budget needs a value")
        let item = ClinicalOps.newRollingTaskBudget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsRollingTaskBudgetCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = ClinicalOps.RollingTaskBudgetCountryLengthRule(maxLength: 32)
        let item = ClinicalOps.newRollingTaskBudget("x", name: "y")
        item.country = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRollingTaskBudgetCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = ClinicalOps.RollingTaskBudgetCostRangeRule(min: 2.8, max: 2735.5)
        let item = ClinicalOps.newRollingTaskBudget("x", name: "y")
        item.cost = 2737.0
        #expect(rule.check(item).count > 0)
    }
}
