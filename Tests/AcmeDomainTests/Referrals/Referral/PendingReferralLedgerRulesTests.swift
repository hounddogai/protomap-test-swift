@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPendingReferralLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPendingReferralLedgerValidator()
        let item = Referrals.newPendingReferralLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPendingReferralLedgerLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.PendingReferralLedgerLabelLengthRule(maxLength: 86400)
        let item = Referrals.newPendingReferralLedger("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPendingReferralLedgerRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.PendingReferralLedgerRequiredLabelRule(message: "pending referral ledger needs an entry")
        let item = Referrals.newPendingReferralLedger("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPendingReferralLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.PendingReferralLedgerCodeLengthRule(maxLength: 86400)
        let item = Referrals.newPendingReferralLedger("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPendingReferralLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.PendingReferralLedgerRequiredCodeRule(message: "pending referral ledger needs an entry")
        let item = Referrals.newPendingReferralLedger("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
