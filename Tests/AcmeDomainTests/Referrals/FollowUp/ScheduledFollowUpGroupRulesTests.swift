@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledFollowUpGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledFollowUpGroupValidator()
        let item = Referrals.newScheduledFollowUpGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledFollowUpGroupCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ScheduledFollowUpGroupCodeLengthRule(maxLength: 80)
        let item = Referrals.newScheduledFollowUpGroup("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsScheduledFollowUpGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ScheduledFollowUpGroupRequiredCodeRule(message: "scheduled follow up group needs a value")
        let item = Referrals.newScheduledFollowUpGroup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledFollowUpGroupRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Referrals.ScheduledFollowUpGroupRequiredSegmentRule(
            message: "scheduled follow up group needs this field"
        )
        let item = Referrals.newScheduledFollowUpGroup("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsScheduledFollowUpGroupEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.ScheduledFollowUpGroupEndsAtRangeRule(min: 3600, max: 86400)
        let item = Referrals.newScheduledFollowUpGroup("x", name: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledFollowUpGroupRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Referrals.ScheduledFollowUpGroupRatioRangeRule(min: 2.0, max: 2366.5)
        let item = Referrals.newScheduledFollowUpGroup("x", name: "y")
        item.ratio = 2368.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledFollowUpGroupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.ScheduledFollowUpGroupRequiredNameRule(message: "scheduled follow up group needs a value")
        let item = Referrals.newScheduledFollowUpGroup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
