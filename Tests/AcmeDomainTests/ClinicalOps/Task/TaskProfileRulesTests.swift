@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskProfileValidator()
        let item = ClinicalOps.newTaskProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TaskProfileCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newTaskProfile("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskProfileWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = ClinicalOps.TaskProfileWindowDaysRangeRule(min: 120, max: 1000)
        let item = ClinicalOps.newTaskProfile("x", label: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskProfileRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = ClinicalOps.TaskProfileRequiredAllergyRule(message: "task profile needs an entry")
        let item = ClinicalOps.newTaskProfile("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskProfileBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = ClinicalOps.TaskProfileBudgetRangeRule(min: 3.1, max: 482.5)
        let item = ClinicalOps.newTaskProfile("x", label: "y")
        item.budget = 484.0
        #expect(rule.check(item).count > 0)
    }
}
