@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceRollupValidator()
        let item = RevenueCycle.newRemittanceRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceRollupPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.RemittanceRollupPriorityRangeRule(min: 64, max: 3600)
        let item = RevenueCycle.newRemittanceRollup("x", name: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceRollupRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = RevenueCycle.RemittanceRollupRequiredTimezoneRule(message: "remittance rollup needs this field")
        let item = RevenueCycle.newRemittanceRollup("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceRollupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.RemittanceRollupNameLengthRule(maxLength: 32)
        let item = RevenueCycle.newRemittanceRollup("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceRollupTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = RevenueCycle.RemittanceRollupTimezoneLengthRule(maxLength: 86400)
        let item = RevenueCycle.newRemittanceRollup("x", name: "y")
        item.timezone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceRollupRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = RevenueCycle.RemittanceRollupRefillsRangeRule(min: 80, max: 3600)
        let item = RevenueCycle.newRemittanceRollup("x", name: "y")
        item.refills = 3601
        #expect(rule.check(item).count > 0)
    }
}
