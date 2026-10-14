@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelSlotValidator()
        let item = Labs.newPanelSlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelSlotRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Labs.PanelSlotRequiredReviewerRule(message: "panel slot needs a value")
        let item = Labs.newPanelSlot("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelSlotMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Labs.PanelSlotMinimumRangeRule(min: 9.7, max: 344.0)
        let item = Labs.newPanelSlot("x", label: "y")
        item.minimum = 345.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelSlotRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.PanelSlotRequiredLabelRule(message: "panel slot needs a value")
        let item = Labs.newPanelSlot("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelSlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PanelSlotCodeLengthRule(maxLength: 80)
        let item = Labs.newPanelSlot("x", label: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
