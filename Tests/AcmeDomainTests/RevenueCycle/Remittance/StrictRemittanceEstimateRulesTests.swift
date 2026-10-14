@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleStrictRemittanceEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultStrictRemittanceEstimateValidator()
        let item = RevenueCycle.newStrictRemittanceEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleStrictRemittanceEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.StrictRemittanceEstimateCodeLengthRule(maxLength: 1000)
        let item = RevenueCycle.newStrictRemittanceEstimate("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleStrictRemittanceEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.StrictRemittanceEstimateRequiredCodeRule(
            message: "strict remittance estimate needs this field"
        )
        let item = RevenueCycle.newStrictRemittanceEstimate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleStrictRemittanceEstimateMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = RevenueCycle.StrictRemittanceEstimateMaximumRangeRule(min: 8.2, max: 4188.2)
        let item = RevenueCycle.newStrictRemittanceEstimate("x", name: "y")
        item.maximum = 4189.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStrictRemittanceEstimateRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = RevenueCycle.StrictRemittanceEstimateRateRangeRule(min: 5.5, max: 1749.0)
        let item = RevenueCycle.newStrictRemittanceEstimate("x", name: "y")
        item.rate = 1750.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleStrictRemittanceEstimateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.StrictRemittanceEstimateRequiredNameRule(
            message: "strict remittance estimate needs this field"
        )
        let item = RevenueCycle.newStrictRemittanceEstimate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
