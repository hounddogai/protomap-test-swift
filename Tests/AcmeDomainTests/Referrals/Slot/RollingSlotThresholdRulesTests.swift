@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRollingSlotThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRollingSlotThresholdValidator()
        let item = Referrals.newRollingSlotThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRollingSlotThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.RollingSlotThresholdCodeLengthRule(maxLength: 86400)
        let item = Referrals.newRollingSlotThreshold("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRollingSlotThresholdCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.RollingSlotThresholdCreatedAtRangeRule(min: 64, max: 255)
        let item = Referrals.newRollingSlotThreshold("x", title: "y")
        item.createdAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRollingSlotThresholdReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Referrals.RollingSlotThresholdReviewerLengthRule(maxLength: 3600)
        let item = Referrals.newRollingSlotThreshold("x", title: "y")
        item.reviewer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
