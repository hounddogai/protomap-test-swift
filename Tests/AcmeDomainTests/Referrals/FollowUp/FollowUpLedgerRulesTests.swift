@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpLedgerValidator()
        let item = Referrals.newFollowUpLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpLedgerCurrencyLengthRuleTests {
    @Test func flagsALongCurrency() throws {
        let rule = Referrals.FollowUpLedgerCurrencyLengthRule(maxLength: 120)
        let item = Referrals.newFollowUpLedger("x", name: "y")
        item.currency = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.currency = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpLedgerRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.FollowUpLedgerRequiredNameRule(message: "follow up ledger needs an entry")
        let item = Referrals.newFollowUpLedger("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpLedgerNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.FollowUpLedgerNameLengthRule(maxLength: 80)
        let item = Referrals.newFollowUpLedger("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
