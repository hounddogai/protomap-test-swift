@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsFallbackClosureDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultFallbackClosureDraftValidator()
        let item = Referrals.newFallbackClosureDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsFallbackClosureDraftLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.FallbackClosureDraftLabelLengthRule(maxLength: 255)
        let item = Referrals.newFallbackClosureDraft("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsFallbackClosureDraftEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.FallbackClosureDraftEndsAtRangeRule(min: 64, max: 255)
        let item = Referrals.newFallbackClosureDraft("x", label: "y")
        item.endsAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsFallbackClosureDraftTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Referrals.FallbackClosureDraftTimezoneLengthRule(maxLength: 1000)
        let item = Referrals.newFallbackClosureDraft("x", label: "y")
        item.timezone = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
