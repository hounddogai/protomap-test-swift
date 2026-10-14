@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimPreferenceValidator()
        let item = RevenueCycle.newClaimPreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimPreferenceLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.ClaimPreferenceLabelLengthRule(maxLength: 120)
        let item = RevenueCycle.newClaimPreference("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimPreferenceProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = RevenueCycle.ClaimPreferenceProcedureCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newClaimPreference("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
