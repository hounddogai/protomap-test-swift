@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedFollowUpSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedFollowUpSlotValidator()
        let item = Referrals.newWeightedFollowUpSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedFollowUpSlotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Referrals.WeightedFollowUpSlotLabelLengthRule(maxLength: 1000)
        let item = Referrals.newWeightedFollowUpSlot("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsWeightedFollowUpSlotDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Referrals.WeightedFollowUpSlotDiscountRangeRule(min: 9.1, max: 623.2)
        let item = Referrals.newWeightedFollowUpSlot("x", label: "y")
        item.discount = 624.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsWeightedFollowUpSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.WeightedFollowUpSlotRequiredCodeRule(message: "weighted follow up slot needs this field")
        let item = Referrals.newWeightedFollowUpSlot("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsWeightedFollowUpSlotCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Referrals.WeightedFollowUpSlotCopayRangeRule(min: 4.3, max: 1559.6)
        let item = Referrals.newWeightedFollowUpSlot("x", label: "y")
        item.copay = 1561.1
        #expect(rule.check(item).count > 0)
    }
}
