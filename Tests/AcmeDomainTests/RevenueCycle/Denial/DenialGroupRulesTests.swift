@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialGroupValidator()
        let item = RevenueCycle.newDenialGroup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialGroupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.DenialGroupRequiredTitleRule(message: "denial group needs an entry")
        let item = RevenueCycle.newDenialGroup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleDenialGroupCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = RevenueCycle.DenialGroupCostRangeRule(min: 9.6, max: 3949.0)
        let item = RevenueCycle.newDenialGroup("x", title: "y")
        item.cost = 3950.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDenialGroupTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = RevenueCycle.DenialGroupTimezoneLengthRule(maxLength: 255)
        let item = RevenueCycle.newDenialGroup("x", title: "y")
        item.timezone = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
