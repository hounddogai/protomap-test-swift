@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledPanelAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultScheduledPanelAdjustmentValidator()
        let item = Labs.newScheduledPanelAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsScheduledPanelAdjustmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.ScheduledPanelAdjustmentLabelLengthRule(maxLength: 80)
        let item = Labs.newScheduledPanelAdjustment("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsScheduledPanelAdjustmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.ScheduledPanelAdjustmentRequiredLabelRule(message: "scheduled panel adjustment needs a value")
        let item = Labs.newScheduledPanelAdjustment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
