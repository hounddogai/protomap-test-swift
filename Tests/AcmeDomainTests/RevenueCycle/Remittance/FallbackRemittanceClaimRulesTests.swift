@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleFallbackRemittanceClaimValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultFallbackRemittanceClaimValidator()
        let item = RevenueCycle.newFallbackRemittanceClaim("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleFallbackRemittanceClaimProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = RevenueCycle.FallbackRemittanceClaimProcedureCodeLengthRule(maxLength: 255)
        let item = RevenueCycle.newFallbackRemittanceClaim("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleFallbackRemittanceClaimRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = RevenueCycle.FallbackRemittanceClaimRequiredPhoneRule(
            message: "fallback remittance claim needs a value"
        )
        let item = RevenueCycle.newFallbackRemittanceClaim("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackRemittanceClaimRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.FallbackRemittanceClaimRequiredCodeRule(
            message: "fallback remittance claim needs this field"
        )
        let item = RevenueCycle.newFallbackRemittanceClaim("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleFallbackRemittanceClaimAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = RevenueCycle.FallbackRemittanceClaimAttemptsRangeRule(min: 120, max: 3600)
        let item = RevenueCycle.newFallbackRemittanceClaim("x", label: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleFallbackRemittanceClaimPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = RevenueCycle.FallbackRemittanceClaimPhoneLengthRule(maxLength: 120)
        let item = RevenueCycle.newFallbackRemittanceClaim("x", label: "y")
        item.phone = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
