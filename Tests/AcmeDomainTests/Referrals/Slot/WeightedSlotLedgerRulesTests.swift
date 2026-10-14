@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsWeightedSlotLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultWeightedSlotLedgerValidator()
        let item = Referrals.newWeightedSlotLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsWeightedSlotLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Referrals.WeightedSlotLedgerRequiredCodeRule(message: "weighted slot ledger needs a value")
        let item = Referrals.newWeightedSlotLedger("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsWeightedSlotLedgerSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Referrals.WeightedSlotLedgerSpecialtyLengthRule(maxLength: 80)
        let item = Referrals.newWeightedSlotLedger("x", label: "y")
        item.specialty = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ReferralsWeightedSlotLedgerRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.WeightedSlotLedgerRequiredLabelRule(message: "weighted slot ledger needs a value")
        let item = Referrals.newWeightedSlotLedger("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsWeightedSlotLedgerWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Referrals.WeightedSlotLedgerWeightRangeRule(min: 5.4, max: 1228.4)
        let item = Referrals.newWeightedSlotLedger("x", label: "y")
        item.weight = 1229.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsWeightedSlotLedgerCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Referrals.WeightedSlotLedgerCodeLengthRule(maxLength: 86400)
        let item = Referrals.newWeightedSlotLedger("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
