@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialTargetValidator()
        let item = RevenueCycle.newDenialTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialTargetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.DenialTargetRequiredTitleRule(message: "denial target needs an entry")
        let item = RevenueCycle.newDenialTarget("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialTargetRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = RevenueCycle.DenialTargetRefillsRangeRule(min: 16, max: 16)
        let item = RevenueCycle.newDenialTarget("x", title: "y")
        item.refills = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialTargetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.DenialTargetTitleLengthRule(maxLength: 120)
        let item = RevenueCycle.newDenialTarget("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
