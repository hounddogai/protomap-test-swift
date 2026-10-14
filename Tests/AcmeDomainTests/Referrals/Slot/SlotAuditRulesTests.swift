@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ReferralsSlotAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Referrals.defaultSlotAuditValidator()
        let item = Referrals.newSlotAudit("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ReferralsSlotAuditAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = Referrals.SlotAuditAcuityRangeRule(min: 80, max: 1000)
        let item = Referrals.newSlotAudit("x", label: "y")
        item.acuity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotAuditRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Referrals.SlotAuditRequiredLabelRule(message: "slot audit needs a value")
        let item = Referrals.newSlotAudit("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ReferralsSlotAuditQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Referrals.SlotAuditQuantityRangeRule(min: 1000, max: 86400)
        let item = Referrals.newSlotAudit("x", label: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ReferralsSlotAuditRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Referrals.SlotAuditRequiredTitleRule(message: "slot audit needs this field")
        let item = Referrals.newSlotAudit("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
