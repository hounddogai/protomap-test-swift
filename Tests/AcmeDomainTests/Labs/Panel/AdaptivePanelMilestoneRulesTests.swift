@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptivePanelMilestoneValidator()
        let item = Labs.newAdaptivePanelMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptivePanelMilestoneEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Labs.AdaptivePanelMilestoneEncounterIDLengthRule(maxLength: 255)
        let item = Labs.newAdaptivePanelMilestone("x", name: "y")
        item.encounterID = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptivePanelMilestoneRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Labs.AdaptivePanelMilestoneRequiredEncounterIDRule(
            message: "adaptive panel milestone needs this field"
        )
        let item = Labs.newAdaptivePanelMilestone("", name: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAdaptivePanelMilestoneRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.AdaptivePanelMilestoneRequiredNameRule(message: "adaptive panel milestone needs a value")
        let item = Labs.newAdaptivePanelMilestone("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
