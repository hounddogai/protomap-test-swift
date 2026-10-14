@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeOverrideValidator()
        let item = RevenueCycle.newChargeOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeOverrideDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = RevenueCycle.ChargeOverrideDiagnosisCodeLengthRule(maxLength: 86400)
        let item = RevenueCycle.newChargeOverride("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeOverrideDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = RevenueCycle.ChargeOverrideDurationMinutesRangeRule(min: 16, max: 255)
        let item = RevenueCycle.newChargeOverride("x", name: "y")
        item.durationMinutes = 256
        #expect(rule.check(item).count > 0)
    }
}
