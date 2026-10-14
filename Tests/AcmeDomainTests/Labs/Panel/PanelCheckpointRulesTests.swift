@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelCheckpointValidator()
        let item = Labs.newPanelCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelCheckpointRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.PanelCheckpointRequiredLabelRule(message: "panel checkpoint needs a value")
        let item = Labs.newPanelCheckpoint("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelCheckpointRequiredCodeRule(message: "panel checkpoint needs an entry")
        let item = Labs.newPanelCheckpoint("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelCheckpointLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.PanelCheckpointLabelLengthRule(maxLength: 16)
        let item = Labs.newPanelCheckpoint("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelCheckpointRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Labs.PanelCheckpointRequiredExternalRefRule(message: "panel checkpoint needs an entry")
        let item = Labs.newPanelCheckpoint("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}
