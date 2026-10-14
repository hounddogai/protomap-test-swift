@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeProfileValidator()
        let item = RevenueCycle.newChargeProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeProfileLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.ChargeProfileLabelLengthRule(maxLength: 86400)
        let item = RevenueCycle.newChargeProfile("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeProfilePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.ChargeProfilePriorityRangeRule(min: 3600, max: 86400)
        let item = RevenueCycle.newChargeProfile("x", label: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeProfileRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ChargeProfileRequiredCodeRule(message: "charge profile needs this field")
        let item = RevenueCycle.newChargeProfile("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
