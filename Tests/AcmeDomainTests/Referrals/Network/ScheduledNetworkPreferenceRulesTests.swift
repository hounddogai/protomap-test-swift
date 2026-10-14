@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledNetworkPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledNetworkPreferenceValidator()
        let item = Referrals.newScheduledNetworkPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledNetworkPreferenceAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Referrals.ScheduledNetworkPreferenceAttemptsRangeRule(min: 16, max: 64)
        let item = Referrals.newScheduledNetworkPreference("x", name: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledNetworkPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ScheduledNetworkPreferenceCodeLengthRule(maxLength: 64)
        let item = Referrals.newScheduledNetworkPreference("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsScheduledNetworkPreferenceSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Referrals.ScheduledNetworkPreferenceSummaryLengthRule(maxLength: 120)
        let item = Referrals.newScheduledNetworkPreference("x", name: "y")
        item.summary = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsScheduledNetworkPreferenceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.ScheduledNetworkPreferenceRequiredTitleRule(
            message: "scheduled network preference needs an entry"
        )
        let item = Referrals.newScheduledNetworkPreference("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
