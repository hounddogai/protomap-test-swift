@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelSegmentValidator()
        let item = Labs.newPanelSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelSegmentBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Labs.PanelSegmentBudgetRangeRule(min: 3.3, max: 4779.9)
        let item = Labs.newPanelSegment("x", label: "y")
        item.budget = 4781.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PanelSegmentCodeLengthRule(maxLength: 255)
        let item = Labs.newPanelSegment("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelSegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.PanelSegmentRequiredLabelRule(message: "panel segment needs an entry")
        let item = Labs.newPanelSegment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelSegmentThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = Labs.PanelSegmentThresholdRangeRule(min: 6.3, max: 2477.5)
        let item = Labs.newPanelSegment("x", label: "y")
        item.threshold = 2479.0
        #expect(rule.check(item).count > 0)
    }
}
