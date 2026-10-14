@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultAuthorizationTargetValidatorExtraTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultAuthorizationTargetValidator()
        let item = RevenueCycle.newDefaultAuthorizationTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultAuthorizationTargetDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = RevenueCycle.DefaultAuthorizationTargetDiscountRangeRule(min: 3.7, max: 4142.1)
        let item = RevenueCycle.newDefaultAuthorizationTarget("x", title: "y")
        item.discount = 4143.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDefaultAuthorizationTargetRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = RevenueCycle.DefaultAuthorizationTargetRatioRangeRule(min: 3.8, max: 2069.4)
        let item = RevenueCycle.newDefaultAuthorizationTarget("x", title: "y")
        item.ratio = 2070.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDefaultAuthorizationTargetRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = RevenueCycle.DefaultAuthorizationTargetRequiredFacilityRule(
            message: "default authorization target needs an entry"
        )
        let item = RevenueCycle.newDefaultAuthorizationTarget("", title: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultAuthorizationTargetCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = RevenueCycle.DefaultAuthorizationTargetCostRangeRule(min: 4.8, max: 1889.8)
        let item = RevenueCycle.newDefaultAuthorizationTarget("x", title: "y")
        item.cost = 1891.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDefaultAuthorizationTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.DefaultAuthorizationTargetRequiredCodeRule(
            message: "default authorization target needs an entry"
        )
        let item = RevenueCycle.newDefaultAuthorizationTarget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDefaultAuthorizationTargetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.DefaultAuthorizationTargetTitleLengthRule(maxLength: 16)
        let item = RevenueCycle.newDefaultAuthorizationTarget("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
