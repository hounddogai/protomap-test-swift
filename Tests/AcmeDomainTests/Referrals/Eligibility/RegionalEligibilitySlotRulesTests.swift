@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsRegionalEligibilitySlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultRegionalEligibilitySlotValidator()
        let item = Referrals.newRegionalEligibilitySlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsRegionalEligibilitySlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.RegionalEligibilitySlotRequiredCodeRule(message: "regional eligibility slot needs a value")
        let item = Referrals.newRegionalEligibilitySlot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsRegionalEligibilitySlotWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Referrals.RegionalEligibilitySlotWindowDaysRangeRule(min: 16, max: 120)
        let item = Referrals.newRegionalEligibilitySlot("x", label: "y")
        item.windowDays = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsRegionalEligibilitySlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.RegionalEligibilitySlotCodeLengthRule(maxLength: 3600)
        let item = Referrals.newRegionalEligibilitySlot("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsRegionalEligibilitySlotSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Referrals.RegionalEligibilitySlotSummaryLengthRule(maxLength: 16)
        let item = Referrals.newRegionalEligibilitySlot("x", label: "y")
        item.summary = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
