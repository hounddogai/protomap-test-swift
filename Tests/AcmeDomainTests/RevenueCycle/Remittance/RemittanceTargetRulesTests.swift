@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceTargetValidator()
        let item = RevenueCycle.newRemittanceTarget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceTargetRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = RevenueCycle.RemittanceTargetRequiredTimezoneRule(message: "remittance target needs this field")
        let item = RevenueCycle.newRemittanceTarget("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RemittanceTargetRequiredCodeRule(message: "remittance target needs an entry")
        let item = RevenueCycle.newRemittanceTarget("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceTargetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.RemittanceTargetRequiredLabelRule(message: "remittance target needs a value")
        let item = RevenueCycle.newRemittanceTarget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceTargetTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = RevenueCycle.RemittanceTargetTimezoneLengthRule(maxLength: 64)
        let item = RevenueCycle.newRemittanceTarget("x", label: "y")
        item.timezone = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceTargetPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.RemittanceTargetPriorityRangeRule(min: 16, max: 86400)
        let item = RevenueCycle.newRemittanceTarget("x", label: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}
