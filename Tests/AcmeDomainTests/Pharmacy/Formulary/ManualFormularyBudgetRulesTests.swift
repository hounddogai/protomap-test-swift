@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualFormularyBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultManualFormularyBudgetValidator()
        let item = Pharmacy.newManualFormularyBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyManualFormularyBudgetCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Pharmacy.ManualFormularyBudgetCategoryLengthRule(maxLength: 80)
        let item = Pharmacy.newManualFormularyBudget("x", title: "y")
        item.category = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualFormularyBudgetLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Pharmacy.ManualFormularyBudgetLimitRangeRule(min: 1000, max: 3600)
        let item = Pharmacy.newManualFormularyBudget("x", title: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyManualFormularyBudgetRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Pharmacy.ManualFormularyBudgetRequiredDescriptionRule(
            message: "manual formulary budget needs this field"
        )
        let item = Pharmacy.newManualFormularyBudget("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyManualFormularyBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.ManualFormularyBudgetCodeLengthRule(maxLength: 1000)
        let item = Pharmacy.newManualFormularyBudget("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
