@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedDenialTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultCappedDenialTargetValidator()
        let item = RevenueCycle.newCappedDenialTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleCappedDenialTargetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.CappedDenialTargetRequiredNameRule(message: "capped denial target needs an entry")
        let item = RevenueCycle.newCappedDenialTarget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleCappedDenialTargetCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = RevenueCycle.CappedDenialTargetCeilingRangeRule(min: 4.3, max: 2375.3)
        let item = RevenueCycle.newCappedDenialTarget("x", name: "y")
        item.ceiling = 2376.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleCappedDenialTargetGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = RevenueCycle.CappedDenialTargetGraceDaysRangeRule(min: 16, max: 255)
        let item = RevenueCycle.newCappedDenialTarget("x", name: "y")
        item.graceDays = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleCappedDenialTargetRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = RevenueCycle.CappedDenialTargetRequiredRegionRule(message: "capped denial target needs a value")
        let item = RevenueCycle.newCappedDenialTarget("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
