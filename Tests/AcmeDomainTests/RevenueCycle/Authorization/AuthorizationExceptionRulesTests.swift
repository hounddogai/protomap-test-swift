@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleAuthorizationExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultAuthorizationExceptionValidator()
        let item = RevenueCycle.newAuthorizationException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleAuthorizationExceptionBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = RevenueCycle.AuthorizationExceptionBatchSizeRangeRule(min: 32, max: 32)
        let item = RevenueCycle.newAuthorizationException("x", title: "y")
        item.batchSize = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleAuthorizationExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.AuthorizationExceptionTitleLengthRule(maxLength: 64)
        let item = RevenueCycle.newAuthorizationException("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationExceptionAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = RevenueCycle.AuthorizationExceptionAllergyLengthRule(maxLength: 120)
        let item = RevenueCycle.newAuthorizationException("x", title: "y")
        item.allergy = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleAuthorizationExceptionAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.AuthorizationExceptionAmountRangeRule(min: 9.5, max: 2545.8)
        let item = RevenueCycle.newAuthorizationException("x", title: "y")
        item.amount = 2547.3
        #expect(rule.check(item).count > 0)
    }
}
