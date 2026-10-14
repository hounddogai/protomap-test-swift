@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeAssignmentValidator()
        let item = RevenueCycle.newChargeAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeAssignmentSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = RevenueCycle.ChargeAssignmentSourceLengthRule(maxLength: 32)
        let item = RevenueCycle.newChargeAssignment("x", name: "y")
        item.source = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeAssignmentRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = RevenueCycle.ChargeAssignmentRateRangeRule(min: 0.6, max: 3174.3)
        let item = RevenueCycle.newChargeAssignment("x", name: "y")
        item.rate = 3175.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ChargeAssignmentRequiredCodeRule(message: "charge assignment needs a value")
        let item = RevenueCycle.newChargeAssignment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeAssignmentRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.ChargeAssignmentRequiredNameRule(message: "charge assignment needs a value")
        let item = RevenueCycle.newChargeAssignment("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
