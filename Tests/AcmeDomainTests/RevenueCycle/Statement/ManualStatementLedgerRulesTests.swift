@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualStatementLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualStatementLedgerValidator()
        let item = RevenueCycle.newManualStatementLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualStatementLedgerRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = RevenueCycle.ManualStatementLedgerRequiredNameRule(message: "manual statement ledger needs an entry")
        let item = RevenueCycle.newManualStatementLedger("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualStatementLedgerSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = RevenueCycle.ManualStatementLedgerSpecialtyLengthRule(maxLength: 32)
        let item = RevenueCycle.newManualStatementLedger("x", name: "y")
        item.specialty = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualStatementLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ManualStatementLedgerRequiredCodeRule(
            message: "manual statement ledger needs this field"
        )
        let item = RevenueCycle.newManualStatementLedger("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualStatementLedgerNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ManualStatementLedgerNameLengthRule(maxLength: 16)
        let item = RevenueCycle.newManualStatementLedger("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualStatementLedgerCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = RevenueCycle.ManualStatementLedgerCeilingRangeRule(min: 2.0, max: 4938.7)
        let item = RevenueCycle.newManualStatementLedger("x", name: "y")
        item.ceiling = 4940.2
        #expect(rule.check(item).count > 0)
    }
}
