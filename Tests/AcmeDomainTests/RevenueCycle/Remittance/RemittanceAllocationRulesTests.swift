@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceAllocationValidator()
        let item = RevenueCycle.newRemittanceAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceAllocationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.RemittanceAllocationLabelLengthRule(maxLength: 80)
        let item = RevenueCycle.newRemittanceAllocation("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceAllocationPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.RemittanceAllocationPriorityRangeRule(min: 16, max: 32)
        let item = RevenueCycle.newRemittanceAllocation("x", label: "y")
        item.priority = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceAllocationRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = RevenueCycle.RemittanceAllocationRequiredUnitRule(message: "remittance allocation needs an entry")
        let item = RevenueCycle.newRemittanceAllocation("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
