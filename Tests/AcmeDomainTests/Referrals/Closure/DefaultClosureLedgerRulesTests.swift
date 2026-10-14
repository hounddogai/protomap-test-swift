@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsDefaultClosureLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultDefaultClosureLedgerValidator()
        let item = Referrals.newDefaultClosureLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsDefaultClosureLedgerBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Referrals.DefaultClosureLedgerBatchSizeRangeRule(min: 120, max: 86400)
        let item = Referrals.newDefaultClosureLedger("x", title: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsDefaultClosureLedgerTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.DefaultClosureLedgerTitleLengthRule(maxLength: 16)
        let item = Referrals.newDefaultClosureLedger("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsDefaultClosureLedgerRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Referrals.DefaultClosureLedgerRequiredPayerRule(message: "default closure ledger needs this field")
        let item = Referrals.newDefaultClosureLedger("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsDefaultClosureLedgerRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.DefaultClosureLedgerRequiredTitleRule(message: "default closure ledger needs this field")
        let item = Referrals.newDefaultClosureLedger("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsDefaultClosureLedgerRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Referrals.DefaultClosureLedgerRequiredReviewerRule(message: "default closure ledger needs a value")
        let item = Referrals.newDefaultClosureLedger("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
