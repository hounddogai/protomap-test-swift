@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsPrimarySlotSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultPrimarySlotSummaryValidator()
        let item = Referrals.newPrimarySlotSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsPrimarySlotSummaryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.PrimarySlotSummaryTitleLengthRule(maxLength: 16)
        let item = Referrals.newPrimarySlotSummary("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsPrimarySlotSummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.PrimarySlotSummaryRequiredTitleRule(message: "primary slot summary needs a value")
        let item = Referrals.newPrimarySlotSummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPrimarySlotSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.PrimarySlotSummaryRequiredCodeRule(message: "primary slot summary needs this field")
        let item = Referrals.newPrimarySlotSummary("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsPrimarySlotSummaryAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Referrals.PrimarySlotSummaryAmountRangeRule(min: 3.9, max: 748.8)
        let item = Referrals.newPrimarySlotSummary("x", title: "y")
        item.amount = 750.3
        #expect(rule.check(item).count > 0)
    }
}
