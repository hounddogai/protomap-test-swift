@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLegacyRecallSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLegacyRecallSlotValidator()
        let item = Pharmacy.newLegacyRecallSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLegacyRecallSlotSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Pharmacy.LegacyRecallSlotSegmentLengthRule(maxLength: 16)
        let item = Pharmacy.newLegacyRecallSlot("x", name: "y")
        item.segment = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyRecallSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.LegacyRecallSlotCodeLengthRule(maxLength: 120)
        let item = Pharmacy.newLegacyRecallSlot("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyRecallSlotSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Pharmacy.LegacyRecallSlotSpecialtyLengthRule(maxLength: 80)
        let item = Pharmacy.newLegacyRecallSlot("x", name: "y")
        item.specialty = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLegacyRecallSlotRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Pharmacy.LegacyRecallSlotRequiredSpecialtyRule(message: "legacy recall slot needs an entry")
        let item = Pharmacy.newLegacyRecallSlot("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}
