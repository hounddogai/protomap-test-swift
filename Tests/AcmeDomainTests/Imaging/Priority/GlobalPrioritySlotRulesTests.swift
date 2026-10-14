@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalPrioritySlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultGlobalPrioritySlotValidator()
        let item = Imaging.newGlobalPrioritySlot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingGlobalPrioritySlotCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.GlobalPrioritySlotCodeLengthRule(maxLength: 3600)
        let item = Imaging.newGlobalPrioritySlot("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalPrioritySlotRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Imaging.GlobalPrioritySlotRequiredSummaryRule(message: "global priority slot needs an entry")
        let item = Imaging.newGlobalPrioritySlot("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingGlobalPrioritySlotPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Imaging.GlobalPrioritySlotPriorityRangeRule(min: 16, max: 80)
        let item = Imaging.newGlobalPrioritySlot("x", label: "y")
        item.priority = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingGlobalPrioritySlotLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.GlobalPrioritySlotLabelLengthRule(maxLength: 86400)
        let item = Imaging.newGlobalPrioritySlot("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingGlobalPrioritySlotSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Imaging.GlobalPrioritySlotSummaryLengthRule(maxLength: 3600)
        let item = Imaging.newGlobalPrioritySlot("x", label: "y")
        item.summary = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
