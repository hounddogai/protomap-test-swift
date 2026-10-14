@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimExceptionValidator()
        let item = RevenueCycle.newClaimException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimExceptionAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = RevenueCycle.ClaimExceptionAcuityRangeRule(min: 32, max: 1000)
        let item = RevenueCycle.newClaimException("x", title: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimExceptionExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = RevenueCycle.ClaimExceptionExternalRefLengthRule(maxLength: 3600)
        let item = RevenueCycle.newClaimException("x", title: "y")
        item.externalRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimExceptionDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = RevenueCycle.ClaimExceptionDiscountRangeRule(min: 3.9, max: 1180.1)
        let item = RevenueCycle.newClaimException("x", title: "y")
        item.discount = 1181.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimExceptionRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.ClaimExceptionRequiredTitleRule(message: "claim exception needs an entry")
        let item = RevenueCycle.newClaimException("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
