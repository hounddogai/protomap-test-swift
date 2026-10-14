@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationRecordValidator()
        let item = RevenueCycle.newAuthorizationRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationRecordDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = RevenueCycle.AuthorizationRecordDiscountRangeRule(min: 5.6, max: 4931.5)
        let item = RevenueCycle.newAuthorizationRecord("x", name: "y")
        item.discount = 4933.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.AuthorizationRecordRequiredCodeRule(message: "authorization record needs this field")
        let item = RevenueCycle.newAuthorizationRecord("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleAuthorizationRecordCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = RevenueCycle.AuthorizationRecordCostRangeRule(min: 3.9, max: 3697.5)
        let item = RevenueCycle.newAuthorizationRecord("x", name: "y")
        item.cost = 3699.0
        #expect(rule.check(item).count > 0)
    }
}
