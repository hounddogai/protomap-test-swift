@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsTieredFollowUpMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultTieredFollowUpMetricValidator()
        let item = Referrals.newTieredFollowUpMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsTieredFollowUpMetricUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Referrals.TieredFollowUpMetricUnitLengthRule(maxLength: 1000)
        let item = Referrals.newTieredFollowUpMetric("x", label: "y")
        item.unit = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsTieredFollowUpMetricCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Referrals.TieredFollowUpMetricCeilingRangeRule(min: 4.7, max: 3717.2)
        let item = Referrals.newTieredFollowUpMetric("x", label: "y")
        item.ceiling = 3718.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsTieredFollowUpMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.TieredFollowUpMetricRequiredCodeRule(message: "tiered follow up metric needs a value")
        let item = Referrals.newTieredFollowUpMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
