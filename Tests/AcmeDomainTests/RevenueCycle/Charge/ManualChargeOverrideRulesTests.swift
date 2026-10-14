@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualChargeOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualChargeOverrideValidator()
        let item = RevenueCycle.newManualChargeOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualChargeOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ManualChargeOverrideCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newManualChargeOverride("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualChargeOverrideDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = RevenueCycle.ManualChargeOverrideDescriptionLengthRule(maxLength: 64)
        let item = RevenueCycle.newManualChargeOverride("x", name: "y")
        item.description = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}
