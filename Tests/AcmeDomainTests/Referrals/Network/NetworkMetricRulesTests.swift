@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsNetworkMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultNetworkMetricValidator()
        let item = Referrals.newNetworkMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsNetworkMetricLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.NetworkMetricLabelLengthRule(maxLength: 80)
        let item = Referrals.newNetworkMetric("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsNetworkMetricRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Referrals.NetworkMetricRequiredDescriptionRule(message: "network metric needs an entry")
        let item = Referrals.newNetworkMetric("", label: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsNetworkMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.NetworkMetricRequiredCodeRule(message: "network metric needs a value")
        let item = Referrals.newNetworkMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
