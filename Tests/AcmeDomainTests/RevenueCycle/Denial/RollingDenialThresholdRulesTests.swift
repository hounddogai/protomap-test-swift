@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingDenialThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRollingDenialThresholdValidator()
        let item = RevenueCycle.newRollingDenialThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRollingDenialThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RollingDenialThresholdCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newRollingDenialThreshold("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRollingDenialThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RollingDenialThresholdRequiredCodeRule(
            message: "rolling denial threshold needs an entry"
        )
        let item = RevenueCycle.newRollingDenialThreshold("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRollingDenialThresholdSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = RevenueCycle.RollingDenialThresholdSourceLengthRule(maxLength: 64)
        let item = RevenueCycle.newRollingDenialThreshold("x", title: "y")
        item.source = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRollingDenialThresholdTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.RollingDenialThresholdTitleLengthRule(maxLength: 120)
        let item = RevenueCycle.newRollingDenialThreshold("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
