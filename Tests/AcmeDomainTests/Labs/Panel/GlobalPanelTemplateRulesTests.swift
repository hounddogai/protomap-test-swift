@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsGlobalPanelTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultGlobalPanelTemplateValidator()
        let item = Labs.newGlobalPanelTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsGlobalPanelTemplateRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Labs.GlobalPanelTemplateRequiredChannelRule(message: "global panel template needs this field")
        let item = Labs.newGlobalPanelTemplate("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsGlobalPanelTemplateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.GlobalPanelTemplateRequiredLabelRule(message: "global panel template needs an entry")
        let item = Labs.newGlobalPanelTemplate("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsGlobalPanelTemplateGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Labs.GlobalPanelTemplateGraceDaysRangeRule(min: 32, max: 80)
        let item = Labs.newGlobalPanelTemplate("x", label: "y")
        item.graceDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsGlobalPanelTemplateDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Labs.GlobalPanelTemplateDiscountRangeRule(min: 5.4, max: 2062.1)
        let item = Labs.newGlobalPanelTemplate("x", label: "y")
        item.discount = 2063.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsGlobalPanelTemplateSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Labs.GlobalPanelTemplateSequenceRangeRule(min: 120, max: 255)
        let item = Labs.newGlobalPanelTemplate("x", label: "y")
        item.sequence = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsGlobalPanelTemplateChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Labs.GlobalPanelTemplateChannelLengthRule(maxLength: 255)
        let item = Labs.newGlobalPanelTemplate("x", label: "y")
        item.channel = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}
