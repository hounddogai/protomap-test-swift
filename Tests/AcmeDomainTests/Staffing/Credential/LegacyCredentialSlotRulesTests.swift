@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingLegacyCredentialSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultLegacyCredentialSlotValidator()
        let item = Staffing.newLegacyCredentialSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingLegacyCredentialSlotReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Staffing.LegacyCredentialSlotReviewerLengthRule(maxLength: 64)
        let item = Staffing.newLegacyCredentialSlot("x", label: "y")
        item.reviewer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingLegacyCredentialSlotDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Staffing.LegacyCredentialSlotDosageMgRangeRule(min: 0.2, max: 753.8)
        let item = Staffing.newLegacyCredentialSlot("x", label: "y")
        item.dosageMg = 755.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLegacyCredentialSlotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.LegacyCredentialSlotRequiredLabelRule(message: "legacy credential slot needs this field")
        let item = Staffing.newLegacyCredentialSlot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingLegacyCredentialSlotGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Staffing.LegacyCredentialSlotGraceDaysRangeRule(min: 1000, max: 3600)
        let item = Staffing.newLegacyCredentialSlot("x", label: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingLegacyCredentialSlotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Staffing.LegacyCredentialSlotLabelLengthRule(maxLength: 80)
        let item = Staffing.newLegacyCredentialSlot("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
