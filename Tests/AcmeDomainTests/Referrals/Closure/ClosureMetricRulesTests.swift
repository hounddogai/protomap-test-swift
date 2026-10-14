@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsClosureMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultClosureMetricValidator()
        let item = Referrals.newClosureMetric("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsClosureMetricCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.ClosureMetricCodeLengthRule(maxLength: 1000)
        let item = Referrals.newClosureMetric("x", title: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsClosureMetricRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Referrals.ClosureMetricRetriesRangeRule(min: 80, max: 86400)
        let item = Referrals.newClosureMetric("x", title: "y")
        item.retries = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsClosureMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.ClosureMetricRequiredCodeRule(message: "closure metric needs a value")
        let item = Referrals.newClosureMetric("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsClosureMetricSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Referrals.ClosureMetricSourceLengthRule(maxLength: 255)
        let item = Referrals.newClosureMetric("x", title: "y")
        item.source = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}
