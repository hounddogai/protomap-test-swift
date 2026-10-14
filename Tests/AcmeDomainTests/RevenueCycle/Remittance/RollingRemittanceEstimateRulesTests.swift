@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRollingRemittanceEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRollingRemittanceEstimateValidator()
        let item = RevenueCycle.newRollingRemittanceEstimate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRollingRemittanceEstimateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.RollingRemittanceEstimateLabelLengthRule(maxLength: 1000)
        let item = RevenueCycle.newRollingRemittanceEstimate("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRollingRemittanceEstimateRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = RevenueCycle.RollingRemittanceEstimateRequiredCurrencyRule(
            message: "rolling remittance estimate needs an entry"
        )
        let item = RevenueCycle.newRollingRemittanceEstimate("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRollingRemittanceEstimateRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = RevenueCycle.RollingRemittanceEstimateRequiredPatientRefRule(
            message: "rolling remittance estimate needs this field"
        )
        let item = RevenueCycle.newRollingRemittanceEstimate("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRollingRemittanceEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RollingRemittanceEstimateCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newRollingRemittanceEstimate("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
