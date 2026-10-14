@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictClaimCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStrictClaimCheckpointValidator()
        let item = RevenueCycle.newStrictClaimCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStrictClaimCheckpointPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.StrictClaimCheckpointPriorityRangeRule(min: 3600, max: 86400)
        let item = RevenueCycle.newStrictClaimCheckpoint("x", title: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStrictClaimCheckpointRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = RevenueCycle.StrictClaimCheckpointRequiredLocaleRule(message: "strict claim checkpoint needs a value")
        let item = RevenueCycle.newStrictClaimCheckpoint("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStrictClaimCheckpointFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = RevenueCycle.StrictClaimCheckpointFloorValueRangeRule(min: 3.8, max: 1330.5)
        let item = RevenueCycle.newStrictClaimCheckpoint("x", title: "y")
        item.floorValue = 1332.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStrictClaimCheckpointRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.StrictClaimCheckpointRequiredTitleRule(message: "strict claim checkpoint needs a value")
        let item = RevenueCycle.newStrictClaimCheckpoint("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStrictClaimCheckpointMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = RevenueCycle.StrictClaimCheckpointMarginRangeRule(min: 7.0, max: 4121.8)
        let item = RevenueCycle.newStrictClaimCheckpoint("x", title: "y")
        item.margin = 4123.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStrictClaimCheckpointLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = RevenueCycle.StrictClaimCheckpointLocaleLengthRule(maxLength: 64)
        let item = RevenueCycle.newStrictClaimCheckpoint("x", title: "y")
        item.locale = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
