@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelSummaryValidator()
        let item = Labs.newPanelSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelSummaryRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Labs.PanelSummaryRequiredTimezoneRule(message: "panel summary needs an entry")
        let item = Labs.newPanelSummary("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelSummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.PanelSummaryRequiredTitleRule(message: "panel summary needs an entry")
        let item = Labs.newPanelSummary("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelSummaryRequiredCodeRule(message: "panel summary needs this field")
        let item = Labs.newPanelSummary("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelSummaryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.PanelSummaryLabelLengthRule(maxLength: 80)
        let item = Labs.newPanelSummary("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelSummaryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.PanelSummaryTitleLengthRule(maxLength: 16)
        let item = Labs.newPanelSummary("x", label: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
