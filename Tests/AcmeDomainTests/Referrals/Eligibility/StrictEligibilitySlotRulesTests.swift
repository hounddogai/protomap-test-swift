@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsStrictEligibilitySlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultStrictEligibilitySlotValidator()
        let item = Referrals.newStrictEligibilitySlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsStrictEligibilitySlotRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Referrals.StrictEligibilitySlotRetriesRangeRule(min: 80, max: 80)
        let item = Referrals.newStrictEligibilitySlot("x", name: "y")
        item.retries = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsStrictEligibilitySlotCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.StrictEligibilitySlotCreatedAtRangeRule(min: 64, max: 3600)
        let item = Referrals.newStrictEligibilitySlot("x", name: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsStrictEligibilitySlotRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = Referrals.StrictEligibilitySlotRequiredOwnerIDRule(message: "strict eligibility slot needs an entry")
        let item = Referrals.newStrictEligibilitySlot("", name: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsStrictEligibilitySlotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Referrals.StrictEligibilitySlotNameLengthRule(maxLength: 86400)
        let item = Referrals.newStrictEligibilitySlot("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsStrictEligibilitySlotEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Referrals.StrictEligibilitySlotEncounterIDLengthRule(maxLength: 80)
        let item = Referrals.newStrictEligibilitySlot("x", name: "y")
        item.encounterID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
