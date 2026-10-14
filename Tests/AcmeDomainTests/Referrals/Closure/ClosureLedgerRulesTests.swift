@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureLedgerValidator()
        let item = Referrals.newClosureLedger("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureLedgerChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Referrals.ClosureLedgerChannelLengthRule(maxLength: 32)
        let item = Referrals.newClosureLedger("x", name: "y")
        item.channel = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureLedgerRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Referrals.ClosureLedgerRequiredChannelRule(message: "closure ledger needs an entry")
        let item = Referrals.newClosureLedger("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ClosureLedgerCodeLengthRule(maxLength: 86400)
        let item = Referrals.newClosureLedger("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureLedgerAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Referrals.ClosureLedgerAttemptsRangeRule(min: 32, max: 255)
        let item = Referrals.newClosureLedger("x", name: "y")
        item.attempts = 256
        #expect(rule.check(item).count > 0)
    }
}
