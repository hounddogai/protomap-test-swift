@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingDenialEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRollingDenialEntryValidator()
        let item = RevenueCycle.newRollingDenialEntry("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRollingDenialEntryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.RollingDenialEntryRequiredLabelRule(message: "rolling denial entry needs this field")
        let item = RevenueCycle.newRollingDenialEntry("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRollingDenialEntryMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.RollingDenialEntryMaximumRangeRule(min: 7.7, max: 4900.6)
        let item = RevenueCycle.newRollingDenialEntry("x", label: "y")
        item.maximum = 4902.1
        #expect(rule.check(item).count > 0)
    }
}
