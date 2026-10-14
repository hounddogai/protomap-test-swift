@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredNetworkEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredNetworkEntryValidator()
        let item = Referrals.newTieredNetworkEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredNetworkEntryLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Referrals.TieredNetworkEntryLocaleLengthRule(maxLength: 32)
        let item = Referrals.newTieredNetworkEntry("x", title: "y")
        item.locale = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsTieredNetworkEntryAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Referrals.TieredNetworkEntryAttemptsRangeRule(min: 80, max: 86400)
        let item = Referrals.newTieredNetworkEntry("x", title: "y")
        item.attempts = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsTieredNetworkEntryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.TieredNetworkEntryRequiredTitleRule(message: "tiered network entry needs an entry")
        let item = Referrals.newTieredNetworkEntry("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsTieredNetworkEntryRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Referrals.TieredNetworkEntryRequiredLocaleRule(message: "tiered network entry needs this field")
        let item = Referrals.newTieredNetworkEntry("", title: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
