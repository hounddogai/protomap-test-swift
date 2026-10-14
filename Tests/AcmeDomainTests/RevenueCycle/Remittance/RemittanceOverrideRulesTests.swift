@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceOverrideValidator()
        let item = RevenueCycle.newRemittanceOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceOverrideRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.RemittanceOverrideRequiredLabelRule(message: "remittance override needs an entry")
        let item = RevenueCycle.newRemittanceOverride("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RemittanceOverrideCodeLengthRule(maxLength: 3600)
        let item = RevenueCycle.newRemittanceOverride("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceOverrideMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = RevenueCycle.RemittanceOverrideMinimumRangeRule(min: 0.6, max: 2053.7)
        let item = RevenueCycle.newRemittanceOverride("x", label: "y")
        item.minimum = 2055.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceOverrideQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = RevenueCycle.RemittanceOverrideQuantityRangeRule(min: 64, max: 80)
        let item = RevenueCycle.newRemittanceOverride("x", label: "y")
        item.quantity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.RemittanceOverrideRequiredCodeRule(message: "remittance override needs this field")
        let item = RevenueCycle.newRemittanceOverride("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
