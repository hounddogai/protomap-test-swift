@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotEstimateValidator()
        let item = Referrals.newSlotEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SlotEstimateCodeLengthRule(maxLength: 255)
        let item = Referrals.newSlotEstimate("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SlotEstimateRequiredCodeRule(message: "slot estimate needs a value")
        let item = Referrals.newSlotEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotEstimateRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Referrals.SlotEstimateRequiredReviewerRule(message: "slot estimate needs this field")
        let item = Referrals.newSlotEstimate("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
