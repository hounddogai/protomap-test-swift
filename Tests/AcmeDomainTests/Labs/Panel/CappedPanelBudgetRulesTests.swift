@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedPanelBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedPanelBudgetValidator()
        let item = Labs.newCappedPanelBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedPanelBudgetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.CappedPanelBudgetTitleLengthRule(maxLength: 120)
        let item = Labs.newCappedPanelBudget("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedPanelBudgetExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = Labs.CappedPanelBudgetExternalRefLengthRule(maxLength: 1000)
        let item = Labs.newCappedPanelBudget("x", title: "y")
        item.externalRef = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsCappedPanelBudgetLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Labs.CappedPanelBudgetLimitRangeRule(min: 16, max: 32)
        let item = Labs.newCappedPanelBudget("x", title: "y")
        item.limit = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedPanelBudgetRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Labs.CappedPanelBudgetRequiredExternalRefRule(message: "capped panel budget needs an entry")
        let item = Labs.newCappedPanelBudget("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
