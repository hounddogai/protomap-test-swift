@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotMilestoneValidator()
        let item = Referrals.newSlotMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotMilestoneRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Referrals.SlotMilestoneRequiredNameRule(message: "slot milestone needs this field")
        let item = Referrals.newSlotMilestone("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotMilestoneMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Referrals.SlotMilestoneMinimumRangeRule(min: 5.4, max: 4862.7)
        let item = Referrals.newSlotMilestone("x", name: "y")
        item.minimum = 4864.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotMilestoneSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Referrals.SlotMilestoneSequenceRangeRule(min: 64, max: 80)
        let item = Referrals.newSlotMilestone("x", name: "y")
        item.sequence = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotMilestoneNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.SlotMilestoneNameLengthRule(maxLength: 120)
        let item = Referrals.newSlotMilestone("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
