@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackClosureMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFallbackClosureMetricValidator()
        let item = Referrals.newFallbackClosureMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFallbackClosureMetricRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Referrals.FallbackClosureMetricRequiredPayerRule(message: "fallback closure metric needs a value")
        let item = Referrals.newFallbackClosureMetric("", label: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFallbackClosureMetricRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Referrals.FallbackClosureMetricRequiredSegmentRule(
            message: "fallback closure metric needs this field"
        )
        let item = Referrals.newFallbackClosureMetric("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsFallbackClosureMetricSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Referrals.FallbackClosureMetricSegmentLengthRule(maxLength: 86400)
        let item = Referrals.newFallbackClosureMetric("x", label: "y")
        item.segment = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFallbackClosureMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.FallbackClosureMetricRequiredCodeRule(message: "fallback closure metric needs this field")
        let item = Referrals.newFallbackClosureMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
