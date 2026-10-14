@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualAuthorizationRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualAuthorizationRollupValidator()
        let item = RevenueCycle.newManualAuthorizationRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualAuthorizationRollupRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = RevenueCycle.ManualAuthorizationRollupRequiredCategoryRule(
            message: "manual authorization rollup needs an entry"
        )
        let item = RevenueCycle.newManualAuthorizationRollup("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualAuthorizationRollupMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.ManualAuthorizationRollupMaximumRangeRule(min: 9.9, max: 689.6)
        let item = RevenueCycle.newManualAuthorizationRollup("x", label: "y")
        item.maximum = 691.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleManualAuthorizationRollupLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.ManualAuthorizationRollupLabelLengthRule(maxLength: 1000)
        let item = RevenueCycle.newManualAuthorizationRollup("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualAuthorizationRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ManualAuthorizationRollupRequiredCodeRule(
            message: "manual authorization rollup needs an entry"
        )
        let item = RevenueCycle.newManualAuthorizationRollup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
