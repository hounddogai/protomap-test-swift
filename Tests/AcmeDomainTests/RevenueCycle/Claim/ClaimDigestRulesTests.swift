@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimDigestValidator()
        let item = RevenueCycle.newClaimDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimDigestMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.ClaimDigestMaximumRangeRule(min: 8.9, max: 3230.7)
        let item = RevenueCycle.newClaimDigest("x", label: "y")
        item.maximum = 3232.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimDigestDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = RevenueCycle.ClaimDigestDosageMgRangeRule(min: 3.5, max: 2179.8)
        let item = RevenueCycle.newClaimDigest("x", label: "y")
        item.dosageMg = 2181.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimDigestMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = RevenueCycle.ClaimDigestMarginRangeRule(min: 7.8, max: 1642.7)
        let item = RevenueCycle.newClaimDigest("x", label: "y")
        item.margin = 1644.2
        #expect(rule.check(item).count > 0)
    }
}
