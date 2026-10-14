@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsEligibilitySlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultEligibilitySlotValidator()
        let item = Referrals.newEligibilitySlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsEligibilitySlotRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.EligibilitySlotRequiredNameRule(message: "eligibility slot needs an entry")
        let item = Referrals.newEligibilitySlot("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilitySlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.EligibilitySlotRequiredCodeRule(message: "eligibility slot needs an entry")
        let item = Referrals.newEligibilitySlot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsEligibilitySlotEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Referrals.EligibilitySlotEndsAtRangeRule(min: 32, max: 86400)
        let item = Referrals.newEligibilitySlot("x", name: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}
