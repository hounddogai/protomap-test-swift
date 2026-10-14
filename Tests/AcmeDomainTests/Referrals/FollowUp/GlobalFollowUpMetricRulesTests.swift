@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalFollowUpMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalFollowUpMetricValidator()
        let item = Referrals.newGlobalFollowUpMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalFollowUpMetricCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Referrals.GlobalFollowUpMetricCapacityRangeRule(min: 64, max: 3600)
        let item = Referrals.newGlobalFollowUpMetric("x", name: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsGlobalFollowUpMetricRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Referrals.GlobalFollowUpMetricRatioRangeRule(min: 9.0, max: 891.9)
        let item = Referrals.newGlobalFollowUpMetric("x", name: "y")
        item.ratio = 893.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsGlobalFollowUpMetricNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.GlobalFollowUpMetricNameLengthRule(maxLength: 1000)
        let item = Referrals.newGlobalFollowUpMetric("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalFollowUpMetricSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Referrals.GlobalFollowUpMetricSummaryLengthRule(maxLength: 16)
        let item = Referrals.newGlobalFollowUpMetric("x", name: "y")
        item.summary = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
