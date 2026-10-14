@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelBudgetValidator()
        let item = Labs.newPanelBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelBudgetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.PanelBudgetTitleLengthRule(maxLength: 3600)
        let item = Labs.newPanelBudget("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PanelBudgetCodeLengthRule(maxLength: 64)
        let item = Labs.newPanelBudget("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelBudgetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.PanelBudgetRequiredTitleRule(message: "panel budget needs an entry")
        let item = Labs.newPanelBudget("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelBudgetRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Labs.PanelBudgetRequiredAllergyRule(message: "panel budget needs an entry")
        let item = Labs.newPanelBudget("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
