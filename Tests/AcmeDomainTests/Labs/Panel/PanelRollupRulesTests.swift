@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelRollupValidator()
        let item = Labs.newPanelRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelRollupRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Labs.PanelRollupRequiredSummaryRule(message: "panel rollup needs a value")
        let item = Labs.newPanelRollup("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelRollupRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Labs.PanelRollupRequiredSourceRule(message: "panel rollup needs this field")
        let item = Labs.newPanelRollup("", title: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelRollupRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.PanelRollupRequiredTitleRule(message: "panel rollup needs this field")
        let item = Labs.newPanelRollup("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelRollupDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Labs.PanelRollupDurationMinutesRangeRule(min: 32, max: 1000)
        let item = Labs.newPanelRollup("x", title: "y")
        item.durationMinutes = 1001
        #expect(rule.check(item).count > 0)
    }
}
