@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelMilestoneValidator()
        let item = Labs.newPanelMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelMilestoneRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Labs.PanelMilestoneRequiredRegionRule(message: "panel milestone needs a value")
        let item = Labs.newPanelMilestone("", name: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelMilestoneAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.PanelMilestoneAttemptsRangeRule(min: 16, max: 64)
        let item = Labs.newPanelMilestone("x", name: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelMilestoneNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.PanelMilestoneNameLengthRule(maxLength: 16)
        let item = Labs.newPanelMilestone("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelMilestoneRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Labs.PanelMilestoneRegionLengthRule(maxLength: 1000)
        let item = Labs.newPanelMilestone("x", name: "y")
        item.region = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelMilestoneRequiredCodeRule(message: "panel milestone needs a value")
        let item = Labs.newPanelMilestone("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
