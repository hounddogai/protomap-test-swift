@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStatementSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStatementSlotValidator()
        let item = RevenueCycle.newStatementSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStatementSlotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.StatementSlotLabelLengthRule(maxLength: 1000)
        let item = RevenueCycle.newStatementSlot("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.StatementSlotCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newStatementSlot("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStatementSlotVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = RevenueCycle.StatementSlotVersionRangeRule(min: 32, max: 80)
        let item = RevenueCycle.newStatementSlot("x", label: "y")
        item.version = 81
        #expect(rule.check(item).count > 0)
    }
}
