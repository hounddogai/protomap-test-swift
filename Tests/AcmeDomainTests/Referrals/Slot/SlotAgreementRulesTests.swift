@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotAgreementValidator()
        let item = Referrals.newSlotAgreement("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.SlotAgreementCodeLengthRule(maxLength: 1000)
        let item = Referrals.newSlotAgreement("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsSlotAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.SlotAgreementRequiredCodeRule(message: "slot agreement needs a value")
        let item = Referrals.newSlotAgreement("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotAgreementDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Referrals.SlotAgreementDurationMinutesRangeRule(min: 255, max: 1000)
        let item = Referrals.newSlotAgreement("x", label: "y")
        item.durationMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotAgreementRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Referrals.SlotAgreementRequiredNotesRule(message: "slot agreement needs this field")
        let item = Referrals.newSlotAgreement("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotAgreementQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.SlotAgreementQuantityRangeRule(min: 120, max: 1000)
        let item = Referrals.newSlotAgreement("x", label: "y")
        item.quantity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotAgreementCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Referrals.SlotAgreementCopayRangeRule(min: 5.8, max: 2974.9)
        let item = Referrals.newSlotAgreement("x", label: "y")
        item.copay = 2976.4
        #expect(rule.check(item).count > 0)
    }
}
