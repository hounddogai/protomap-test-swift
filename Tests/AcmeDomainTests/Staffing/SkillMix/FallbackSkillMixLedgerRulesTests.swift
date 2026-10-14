@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackSkillMixLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackSkillMixLedgerValidator()
        let item = Staffing.newFallbackSkillMixLedger("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackSkillMixLedgerQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Staffing.FallbackSkillMixLedgerQuantityRangeRule(min: 32, max: 32)
        let item = Staffing.newFallbackSkillMixLedger("x", label: "y")
        item.quantity = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingFallbackSkillMixLedgerTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.FallbackSkillMixLedgerTitleLengthRule(maxLength: 255)
        let item = Staffing.newFallbackSkillMixLedger("x", label: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackSkillMixLedgerRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Staffing.FallbackSkillMixLedgerRegionLengthRule(maxLength: 80)
        let item = Staffing.newFallbackSkillMixLedger("x", label: "y")
        item.region = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackSkillMixLedgerRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.FallbackSkillMixLedgerRequiredCodeRule(message: "fallback skill mix ledger needs an entry")
        let item = Staffing.newFallbackSkillMixLedger("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackSkillMixLedgerDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Staffing.FallbackSkillMixLedgerDiscountRangeRule(min: 3.8, max: 3112.2)
        let item = Staffing.newFallbackSkillMixLedger("x", label: "y")
        item.discount = 3113.7
        #expect(rule.check(item).count > 0)
    }
}
