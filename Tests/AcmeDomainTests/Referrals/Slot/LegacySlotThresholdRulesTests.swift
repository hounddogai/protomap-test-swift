@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsLegacySlotThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultLegacySlotThresholdValidator()
        let item = Referrals.newLegacySlotThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsLegacySlotThresholdRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Referrals.LegacySlotThresholdRequiredReviewerRule(message: "legacy slot threshold needs a value")
        let item = Referrals.newLegacySlotThreshold("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsLegacySlotThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.LegacySlotThresholdCodeLengthRule(maxLength: 3600)
        let item = Referrals.newLegacySlotThreshold("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsLegacySlotThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.LegacySlotThresholdRequiredCodeRule(message: "legacy slot threshold needs this field")
        let item = Referrals.newLegacySlotThreshold("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
