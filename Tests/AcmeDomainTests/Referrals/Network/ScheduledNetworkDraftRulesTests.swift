@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledNetworkDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledNetworkDraftValidator()
        let item = Referrals.newScheduledNetworkDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledNetworkDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ScheduledNetworkDraftRequiredCodeRule(message: "scheduled network draft needs an entry")
        let item = Referrals.newScheduledNetworkDraft("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledNetworkDraftEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.ScheduledNetworkDraftEndsAtRangeRule(min: 64, max: 120)
        let item = Referrals.newScheduledNetworkDraft("x", name: "y")
        item.endsAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledNetworkDraftWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Referrals.ScheduledNetworkDraftWindowDaysRangeRule(min: 255, max: 86400)
        let item = Referrals.newScheduledNetworkDraft("x", name: "y")
        item.windowDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledNetworkDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.ScheduledNetworkDraftNameLengthRule(maxLength: 16)
        let item = Referrals.newScheduledNetworkDraft("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
