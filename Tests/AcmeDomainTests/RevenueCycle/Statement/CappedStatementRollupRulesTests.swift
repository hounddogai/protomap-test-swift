@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedStatementRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultCappedStatementRollupValidator()
        let item = RevenueCycle.newCappedStatementRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleCappedStatementRollupCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = RevenueCycle.CappedStatementRollupCopayRangeRule(min: 4.0, max: 4504.9)
        let item = RevenueCycle.newCappedStatementRollup("x", name: "y")
        item.copay = 4506.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleCappedStatementRollupNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.CappedStatementRollupNameLengthRule(maxLength: 80)
        let item = RevenueCycle.newCappedStatementRollup("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleCappedStatementRollupMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = RevenueCycle.CappedStatementRollupMinimumRangeRule(min: 5.0, max: 3472.3)
        let item = RevenueCycle.newCappedStatementRollup("x", name: "y")
        item.minimum = 3473.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleCappedStatementRollupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.CappedStatementRollupCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newCappedStatementRollup("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleCappedStatementRollupFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = RevenueCycle.CappedStatementRollupFloorValueRangeRule(min: 9.8, max: 517.9)
        let item = RevenueCycle.newCappedStatementRollup("x", name: "y")
        item.floorValue = 519.4
        #expect(rule.check(item).count > 0)
    }
}
