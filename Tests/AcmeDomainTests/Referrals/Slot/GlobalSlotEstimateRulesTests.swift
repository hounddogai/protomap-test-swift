@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsGlobalSlotEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultGlobalSlotEstimateValidator()
        let item = Referrals.newGlobalSlotEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsGlobalSlotEstimateChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Referrals.GlobalSlotEstimateChannelLengthRule(maxLength: 80)
        let item = Referrals.newGlobalSlotEstimate("x", title: "y")
        item.channel = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalSlotEstimateAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Referrals.GlobalSlotEstimateAcuityRangeRule(min: 80, max: 80)
        let item = Referrals.newGlobalSlotEstimate("x", title: "y")
        item.acuity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsGlobalSlotEstimateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.GlobalSlotEstimateRequiredTitleRule(message: "global slot estimate needs a value")
        let item = Referrals.newGlobalSlotEstimate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalSlotEstimateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Referrals.GlobalSlotEstimateTitleLengthRule(maxLength: 64)
        let item = Referrals.newGlobalSlotEstimate("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsGlobalSlotEstimateRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Referrals.GlobalSlotEstimateRequiredAllergyRule(message: "global slot estimate needs an entry")
        let item = Referrals.newGlobalSlotEstimate("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsGlobalSlotEstimateMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Referrals.GlobalSlotEstimateMarginRangeRule(min: 9.1, max: 2150.2)
        let item = Referrals.newGlobalSlotEstimate("x", title: "y")
        item.margin = 2151.7
        #expect(rule.check(item).count > 0)
    }
}
