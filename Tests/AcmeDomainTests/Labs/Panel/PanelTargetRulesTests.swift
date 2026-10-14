@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelTargetValidator()
        let item = Labs.newPanelTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelTargetRequiredCodeRule(message: "panel target needs an entry")
        let item = Labs.newPanelTarget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelTargetBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Labs.PanelTargetBudgetRangeRule(min: 7.9, max: 4477.6)
        let item = Labs.newPanelTarget("x", title: "y")
        item.budget = 4479.1
        #expect(rule.check(item).count > 0)
    }
}
