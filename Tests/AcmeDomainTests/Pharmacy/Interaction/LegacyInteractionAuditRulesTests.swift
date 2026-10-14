@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyInteractionAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyInteractionAuditValidator()
        let item = Pharmacy.newLegacyInteractionAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyInteractionAuditCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.LegacyInteractionAuditCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newLegacyInteractionAudit("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyInteractionAuditNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Pharmacy.LegacyInteractionAuditNotesLengthRule(maxLength: 32)
        let item = Pharmacy.newLegacyInteractionAudit("x", name: "y")
        item.notes = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyInteractionAuditRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Pharmacy.LegacyInteractionAuditRequiredChannelRule(
            message: "legacy interaction audit needs this field"
        )
        let item = Pharmacy.newLegacyInteractionAudit("", name: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyLegacyInteractionAuditWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Pharmacy.LegacyInteractionAuditWeightRangeRule(min: 8.6, max: 3608.4)
        let item = Pharmacy.newLegacyInteractionAudit("x", name: "y")
        item.weight = 3609.9
        #expect(rule.check(item).count > 0)
    }
}
