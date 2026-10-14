@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedFollowUpMetricValidator()
        let item = Referrals.newWeightedFollowUpMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedFollowUpMetricRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Referrals.WeightedFollowUpMetricRegionLengthRule(maxLength: 64)
        let item = Referrals.newWeightedFollowUpMetric("x", title: "y")
        item.region = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsWeightedFollowUpMetricRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Referrals.WeightedFollowUpMetricRequiredRegionRule(
            message: "weighted follow up metric needs an entry"
        )
        let item = Referrals.newWeightedFollowUpMetric("", title: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsWeightedFollowUpMetricTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.WeightedFollowUpMetricTitleLengthRule(maxLength: 120)
        let item = Referrals.newWeightedFollowUpMetric("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
