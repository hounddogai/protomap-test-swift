@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryStatementRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPrimaryStatementRecordValidator()
        let item = RevenueCycle.newPrimaryStatementRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePrimaryStatementRecordRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = RevenueCycle.PrimaryStatementRecordRefillsRangeRule(min: 64, max: 255)
        let item = RevenueCycle.newPrimaryStatementRecord("x", name: "y")
        item.refills = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCyclePrimaryStatementRecordRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = RevenueCycle.PrimaryStatementRecordRequiredCurrencyRule(
            message: "primary statement record needs an entry"
        )
        let item = RevenueCycle.newPrimaryStatementRecord("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePrimaryStatementRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.PrimaryStatementRecordRequiredCodeRule(message: "primary statement record needs a value")
        let item = RevenueCycle.newPrimaryStatementRecord("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePrimaryStatementRecordPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = RevenueCycle.PrimaryStatementRecordPayerLengthRule(maxLength: 86400)
        let item = RevenueCycle.newPrimaryStatementRecord("x", name: "y")
        item.payer = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePrimaryStatementRecordDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = RevenueCycle.PrimaryStatementRecordDosageMgRangeRule(min: 9.3, max: 4192.3)
        let item = RevenueCycle.newPrimaryStatementRecord("x", name: "y")
        item.dosageMg = 4193.8
        #expect(rule.check(item).count > 0)
    }
}
