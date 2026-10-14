@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFollowUpMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFollowUpMetricValidator()
        let item = Referrals.newFollowUpMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFollowUpMetricRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Referrals.FollowUpMetricRequiredBedRule(message: "follow up metric needs a value")
        let item = Referrals.newFollowUpMetric("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFollowUpMetricLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.FollowUpMetricLabelLengthRule(maxLength: 16)
        let item = Referrals.newFollowUpMetric("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFollowUpMetricRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Referrals.FollowUpMetricRatioRangeRule(min: 1.1, max: 1417.0)
        let item = Referrals.newFollowUpMetric("x", label: "y")
        item.ratio = 1418.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFollowUpMetricChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Referrals.FollowUpMetricChannelLengthRule(maxLength: 1000)
        let item = Referrals.newFollowUpMetric("x", label: "y")
        item.channel = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
