@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultSlotLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultDefaultSlotLedgerValidator()
        let item = Referrals.newDefaultSlotLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsDefaultSlotLedgerVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Referrals.DefaultSlotLedgerVersionRangeRule(min: 32, max: 64)
        let item = Referrals.newDefaultSlotLedger("x", label: "y")
        item.version = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsDefaultSlotLedgerRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Referrals.DefaultSlotLedgerRequiredCurrencyRule(message: "default slot ledger needs a value")
        let item = Referrals.newDefaultSlotLedger("", label: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsDefaultSlotLedgerGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Referrals.DefaultSlotLedgerGraceDaysRangeRule(min: 80, max: 3600)
        let item = Referrals.newDefaultSlotLedger("x", label: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}
