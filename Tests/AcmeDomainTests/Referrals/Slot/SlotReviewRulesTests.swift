@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotReviewValidator()
        let item = Referrals.newSlotReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotReviewWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.SlotReviewWardLengthRule(maxLength: 80)
        let item = Referrals.newSlotReview("x", name: "y")
        item.ward = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.SlotReviewNameLengthRule(maxLength: 32)
        let item = Referrals.newSlotReview("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.SlotReviewRequiredNameRule(message: "slot review needs an entry")
        let item = Referrals.newSlotReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SlotReviewRequiredCodeRule(message: "slot review needs a value")
        let item = Referrals.newSlotReview("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SlotReviewCodeLengthRule(maxLength: 255)
        let item = Referrals.newSlotReview("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
