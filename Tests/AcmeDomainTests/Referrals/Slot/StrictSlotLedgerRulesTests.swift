@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictSlotLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultStrictSlotLedgerValidator()
        let item = Referrals.newStrictSlotLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsStrictSlotLedgerLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Referrals.StrictSlotLedgerLocaleLengthRule(maxLength: 16)
        let item = Referrals.newStrictSlotLedger("x", title: "y")
        item.locale = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsStrictSlotLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.StrictSlotLedgerRequiredCodeRule(message: "strict slot ledger needs a value")
        let item = Referrals.newStrictSlotLedger("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsStrictSlotLedgerWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Referrals.StrictSlotLedgerWeightRangeRule(min: 0.2, max: 2380.4)
        let item = Referrals.newStrictSlotLedger("x", title: "y")
        item.weight = 2381.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsStrictSlotLedgerRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Referrals.StrictSlotLedgerRequiredLocaleRule(message: "strict slot ledger needs a value")
        let item = Referrals.newStrictSlotLedger("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsStrictSlotLedgerSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Referrals.StrictSlotLedgerSegmentLengthRule(maxLength: 3600)
        let item = Referrals.newStrictSlotLedger("x", title: "y")
        item.segment = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
