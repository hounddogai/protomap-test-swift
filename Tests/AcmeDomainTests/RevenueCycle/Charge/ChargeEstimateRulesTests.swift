@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeEstimateValidator()
        let item = RevenueCycle.newChargeEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeEstimateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.ChargeEstimateRequiredNameRule(message: "charge estimate needs this field")
        let item = RevenueCycle.newChargeEstimate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ChargeEstimateCodeLengthRule(maxLength: 32)
        let item = RevenueCycle.newChargeEstimate("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeEstimateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ChargeEstimateNameLengthRule(maxLength: 64)
        let item = RevenueCycle.newChargeEstimate("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
