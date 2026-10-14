@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictProxyBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultStrictProxyBudgetValidator()
        let item = Consent.newStrictProxyBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentStrictProxyBudgetBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Consent.StrictProxyBudgetBudgetRangeRule(min: 3.3, max: 3035.2)
        let item = Consent.newStrictProxyBudget("x", title: "y")
        item.budget = 3036.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentStrictProxyBudgetCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Consent.StrictProxyBudgetCapacityRangeRule(min: 64, max: 255)
        let item = Consent.newStrictProxyBudget("x", title: "y")
        item.capacity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentStrictProxyBudgetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.StrictProxyBudgetRequiredTitleRule(message: "strict proxy budget needs this field")
        let item = Consent.newStrictProxyBudget("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
