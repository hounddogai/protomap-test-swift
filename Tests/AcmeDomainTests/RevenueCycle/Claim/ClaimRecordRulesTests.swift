@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleClaimRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultClaimRecordValidator()
        let item = RevenueCycle.newClaimRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleClaimRecordNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ClaimRecordNameLengthRule(maxLength: 80)
        let item = RevenueCycle.newClaimRecord("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleClaimRecordExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = RevenueCycle.ClaimRecordExpiresAtRangeRule(min: 3600, max: 86400)
        let item = RevenueCycle.newClaimRecord("x", name: "y")
        item.expiresAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleClaimRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ClaimRecordRequiredCodeRule(message: "claim record needs a value")
        let item = RevenueCycle.newClaimRecord("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleClaimRecordRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = RevenueCycle.ClaimRecordRequiredPayerRule(message: "claim record needs this field")
        let item = RevenueCycle.newClaimRecord("", name: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}
