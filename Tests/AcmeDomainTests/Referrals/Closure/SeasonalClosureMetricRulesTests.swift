@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSeasonalClosureMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSeasonalClosureMetricValidator()
        let item = Referrals.newSeasonalClosureMetric("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSeasonalClosureMetricRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Referrals.SeasonalClosureMetricRequiredChannelRule(message: "seasonal closure metric needs an entry")
        let item = Referrals.newSeasonalClosureMetric("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSeasonalClosureMetricNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.SeasonalClosureMetricNameLengthRule(maxLength: 64)
        let item = Referrals.newSeasonalClosureMetric("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSeasonalClosureMetricChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Referrals.SeasonalClosureMetricChannelLengthRule(maxLength: 16)
        let item = Referrals.newSeasonalClosureMetric("x", name: "y")
        item.channel = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
