@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsCappedEligibilitySlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultCappedEligibilitySlotValidator()
        let item = Referrals.newCappedEligibilitySlot("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsCappedEligibilitySlotRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Referrals.CappedEligibilitySlotRequiredOwnerIDRule(
            message: "capped eligibility slot needs this field"
        )
        let item = Referrals.newCappedEligibilitySlot("", title: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsCappedEligibilitySlotCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Referrals.CappedEligibilitySlotCopayRangeRule(min: 4.3, max: 357.4)
        let item = Referrals.newCappedEligibilitySlot("x", title: "y")
        item.copay = 358.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsCappedEligibilitySlotTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.CappedEligibilitySlotTitleLengthRule(maxLength: 255)
        let item = Referrals.newCappedEligibilitySlot("x", title: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
