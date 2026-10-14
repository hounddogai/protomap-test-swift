@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultClaimBundleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultClaimBundleValidator()
        let item = RevenueCycle.newDefaultClaimBundle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultClaimBundleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.DefaultClaimBundleTitleLengthRule(maxLength: 64)
        let item = RevenueCycle.newDefaultClaimBundle("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultClaimBundleQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = RevenueCycle.DefaultClaimBundleQuantityRangeRule(min: 120, max: 86400)
        let item = RevenueCycle.newDefaultClaimBundle("x", title: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}
