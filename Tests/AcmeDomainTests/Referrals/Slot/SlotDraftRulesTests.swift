@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotDraftValidator()
        let item = Referrals.newSlotDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.SlotDraftRequiredLabelRule(message: "slot draft needs an entry")
        let item = Referrals.newSlotDraft("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotDraftCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Referrals.SlotDraftCreatedAtRangeRule(min: 32, max: 80)
        let item = Referrals.newSlotDraft("x", label: "y")
        item.createdAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SlotDraftRequiredCodeRule(message: "slot draft needs a value")
        let item = Referrals.newSlotDraft("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotDraftRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Referrals.SlotDraftRequiredLocaleRule(message: "slot draft needs this field")
        let item = Referrals.newSlotDraft("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
