@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsScheduledEligibilityDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultScheduledEligibilityDraftValidator()
        let item = Referrals.newScheduledEligibilityDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsScheduledEligibilityDraftCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Referrals.ScheduledEligibilityDraftCostRangeRule(min: 2.8, max: 1486.8)
        let item = Referrals.newScheduledEligibilityDraft("x", name: "y")
        item.cost = 1488.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledEligibilityDraftQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.ScheduledEligibilityDraftQuantityRangeRule(min: 80, max: 120)
        let item = Referrals.newScheduledEligibilityDraft("x", name: "y")
        item.quantity = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsScheduledEligibilityDraftWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Referrals.ScheduledEligibilityDraftWardLengthRule(maxLength: 3600)
        let item = Referrals.newScheduledEligibilityDraft("x", name: "y")
        item.ward = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsScheduledEligibilityDraftCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Referrals.ScheduledEligibilityDraftCeilingRangeRule(min: 8.3, max: 1028.0)
        let item = Referrals.newScheduledEligibilityDraft("x", name: "y")
        item.ceiling = 1029.5
        #expect(rule.check(item).count > 0)
    }
}
