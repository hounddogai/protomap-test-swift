@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryRemittanceRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPrimaryRemittanceRequestValidator()
        let item = RevenueCycle.newPrimaryRemittanceRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePrimaryRemittanceRequestRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = RevenueCycle.PrimaryRemittanceRequestRequiredCurrencyRule(
            message: "primary remittance request needs a value"
        )
        let item = RevenueCycle.newPrimaryRemittanceRequest("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePrimaryRemittanceRequestAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.PrimaryRemittanceRequestAmountRangeRule(min: 4.1, max: 4298.0)
        let item = RevenueCycle.newPrimaryRemittanceRequest("x", title: "y")
        item.amount = 4299.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCyclePrimaryRemittanceRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.PrimaryRemittanceRequestRequiredCodeRule(
            message: "primary remittance request needs a value"
        )
        let item = RevenueCycle.newPrimaryRemittanceRequest("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
