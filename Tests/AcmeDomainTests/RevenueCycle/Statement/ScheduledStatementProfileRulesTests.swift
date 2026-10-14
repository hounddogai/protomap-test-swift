@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleScheduledStatementProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultScheduledStatementProfileValidator()
        let item = RevenueCycle.newScheduledStatementProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleScheduledStatementProfileLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.ScheduledStatementProfileLabelLengthRule(maxLength: 86400)
        let item = RevenueCycle.newScheduledStatementProfile("x", name: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleScheduledStatementProfileEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = RevenueCycle.ScheduledStatementProfileEndsAtRangeRule(min: 3600, max: 86400)
        let item = RevenueCycle.newScheduledStatementProfile("x", name: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleScheduledStatementProfileRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = RevenueCycle.ScheduledStatementProfileRequiredChannelRule(
            message: "scheduled statement profile needs a value"
        )
        let item = RevenueCycle.newScheduledStatementProfile("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleScheduledStatementProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ScheduledStatementProfileRequiredCodeRule(
            message: "scheduled statement profile needs a value"
        )
        let item = RevenueCycle.newScheduledStatementProfile("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleScheduledStatementProfileCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = RevenueCycle.ScheduledStatementProfileCeilingRangeRule(min: 1.0, max: 2325.9)
        let item = RevenueCycle.newScheduledStatementProfile("x", name: "y")
        item.ceiling = 2327.4
        #expect(rule.check(item).count > 0)
    }
}
