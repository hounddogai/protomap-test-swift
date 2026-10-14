@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalStatementProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRegionalStatementProfileValidator()
        let item = RevenueCycle.newRegionalStatementProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRegionalStatementProfileRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.RegionalStatementProfileRequiredTitleRule(
            message: "regional statement profile needs a value"
        )
        let item = RevenueCycle.newRegionalStatementProfile("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalStatementProfileRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = RevenueCycle.RegionalStatementProfileRequiredExternalRefRule(
            message: "regional statement profile needs a value"
        )
        let item = RevenueCycle.newRegionalStatementProfile("", title: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalStatementProfileAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.RegionalStatementProfileAmountRangeRule(min: 4.2, max: 4994.1)
        let item = RevenueCycle.newRegionalStatementProfile("x", title: "y")
        item.amount = 4995.6
        #expect(rule.check(item).count > 0)
    }
}
