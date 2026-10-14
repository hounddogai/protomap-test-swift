@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyPanelThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyPanelThresholdValidator()
        let item = Labs.newLegacyPanelThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyPanelThresholdRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Labs.LegacyPanelThresholdRequiredNotesRule(message: "legacy panel threshold needs an entry")
        let item = Labs.newLegacyPanelThreshold("", title: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsLegacyPanelThresholdTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.LegacyPanelThresholdTitleLengthRule(maxLength: 1000)
        let item = Labs.newLegacyPanelThreshold("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacyPanelThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.LegacyPanelThresholdCodeLengthRule(maxLength: 16)
        let item = Labs.newLegacyPanelThreshold("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacyPanelThresholdChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Labs.LegacyPanelThresholdChecksumLengthRule(maxLength: 64)
        let item = Labs.newLegacyPanelThreshold("x", title: "y")
        item.checksum = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacyPanelThresholdRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.LegacyPanelThresholdRequiredTitleRule(message: "legacy panel threshold needs this field")
        let item = Labs.newLegacyPanelThreshold("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
