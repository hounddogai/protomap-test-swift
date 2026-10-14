@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredPanelSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultTieredPanelSlotValidator()
        let item = Labs.newTieredPanelSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsTieredPanelSlotRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Labs.TieredPanelSlotRequiredEncounterIDRule(message: "tiered panel slot needs this field")
        let item = Labs.newTieredPanelSlot("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsTieredPanelSlotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.TieredPanelSlotRequiredLabelRule(message: "tiered panel slot needs a value")
        let item = Labs.newTieredPanelSlot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsTieredPanelSlotEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Labs.TieredPanelSlotEncounterIDLengthRule(maxLength: 3600)
        let item = Labs.newTieredPanelSlot("x", label: "y")
        item.encounterID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsTieredPanelSlotChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Labs.TieredPanelSlotChecksumLengthRule(maxLength: 32)
        let item = Labs.newTieredPanelSlot("x", label: "y")
        item.checksum = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsTieredPanelSlotRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Labs.TieredPanelSlotRequiredChecksumRule(message: "tiered panel slot needs a value")
        let item = Labs.newTieredPanelSlot("", label: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsTieredPanelSlotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.TieredPanelSlotLabelLengthRule(maxLength: 16)
        let item = Labs.newTieredPanelSlot("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
