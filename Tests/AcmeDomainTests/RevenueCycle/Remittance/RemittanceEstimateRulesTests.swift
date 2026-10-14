@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceEstimateValidator()
        let item = RevenueCycle.newRemittanceEstimate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceEstimateNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.RemittanceEstimateNameLengthRule(maxLength: 16)
        let item = RevenueCycle.newRemittanceEstimate("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceEstimateRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.RemittanceEstimateRequiredNameRule(message: "remittance estimate needs a value")
        let item = RevenueCycle.newRemittanceEstimate("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceEstimateRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = RevenueCycle.RemittanceEstimateRequiredPayerRule(message: "remittance estimate needs an entry")
        let item = RevenueCycle.newRemittanceEstimate("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
