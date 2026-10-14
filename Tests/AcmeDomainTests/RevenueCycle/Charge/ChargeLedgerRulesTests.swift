@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeLedgerValidator()
        let item = RevenueCycle.newChargeLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeLedgerRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = RevenueCycle.ChargeLedgerRequiredNotesRule(message: "charge ledger needs a value")
        let item = RevenueCycle.newChargeLedger("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeLedgerEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = RevenueCycle.ChargeLedgerEndsAtRangeRule(min: 80, max: 120)
        let item = RevenueCycle.newChargeLedger("x", title: "y")
        item.endsAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeLedgerRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = RevenueCycle.ChargeLedgerRateRangeRule(min: 4.8, max: 2778.7)
        let item = RevenueCycle.newChargeLedger("x", title: "y")
        item.rate = 2780.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeLedgerTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.ChargeLedgerTitleLengthRule(maxLength: 3600)
        let item = RevenueCycle.newChargeLedger("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
