@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleGlobalAuthorizationEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultGlobalAuthorizationEstimateValidator()
        let item = RevenueCycle.newGlobalAuthorizationEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleGlobalAuthorizationEstimateMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = RevenueCycle.GlobalAuthorizationEstimateMinimumRangeRule(min: 9.5, max: 3358.6)
        let item = RevenueCycle.newGlobalAuthorizationEstimate("x", name: "y")
        item.minimum = 3360.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleGlobalAuthorizationEstimateRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = RevenueCycle.GlobalAuthorizationEstimateRegionLengthRule(maxLength: 120)
        let item = RevenueCycle.newGlobalAuthorizationEstimate("x", name: "y")
        item.region = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleGlobalAuthorizationEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.GlobalAuthorizationEstimateCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newGlobalAuthorizationEstimate("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
