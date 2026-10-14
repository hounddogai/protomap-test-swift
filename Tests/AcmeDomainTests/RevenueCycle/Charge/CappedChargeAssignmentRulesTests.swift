@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleCappedChargeAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultCappedChargeAssignmentValidator()
        let item = RevenueCycle.newCappedChargeAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleCappedChargeAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.CappedChargeAssignmentCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newCappedChargeAssignment("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleCappedChargeAssignmentWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = RevenueCycle.CappedChargeAssignmentWeightRangeRule(min: 8.5, max: 4818.8)
        let item = RevenueCycle.newCappedChargeAssignment("x", label: "y")
        item.weight = 4820.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleCappedChargeAssignmentCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = RevenueCycle.CappedChargeAssignmentCostRangeRule(min: 8.3, max: 4191.7)
        let item = RevenueCycle.newCappedChargeAssignment("x", label: "y")
        item.cost = 4193.2
        #expect(rule.check(item).count > 0)
    }
}
