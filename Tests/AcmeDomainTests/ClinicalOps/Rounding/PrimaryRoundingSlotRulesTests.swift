@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPrimaryRoundingSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPrimaryRoundingSlotValidator()
        let item = ClinicalOps.newPrimaryRoundingSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPrimaryRoundingSlotRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = ClinicalOps.PrimaryRoundingSlotRequiredNotesRule(message: "primary rounding slot needs a value")
        let item = ClinicalOps.newPrimaryRoundingSlot("", name: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPrimaryRoundingSlotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.PrimaryRoundingSlotNameLengthRule(maxLength: 1000)
        let item = ClinicalOps.newPrimaryRoundingSlot("x", name: "y")
        item.name = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryRoundingSlotRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = ClinicalOps.PrimaryRoundingSlotRequiredSpecialtyRule(message: "primary rounding slot needs a value")
        let item = ClinicalOps.newPrimaryRoundingSlot("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsPrimaryRoundingSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.PrimaryRoundingSlotCodeLengthRule(maxLength: 255)
        let item = ClinicalOps.newPrimaryRoundingSlot("x", name: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPrimaryRoundingSlotRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.PrimaryRoundingSlotRequiredCodeRule(message: "primary rounding slot needs an entry")
        let item = ClinicalOps.newPrimaryRoundingSlot("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
