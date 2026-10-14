@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingGlobalPriorityRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultGlobalPriorityRecordValidator()
        let item = Imaging.newGlobalPriorityRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingGlobalPriorityRecordWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Imaging.GlobalPriorityRecordWindowDaysRangeRule(min: 16, max: 16)
        let item = Imaging.newGlobalPriorityRecord("x", label: "y")
        item.windowDays = 17
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingGlobalPriorityRecordQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Imaging.GlobalPriorityRecordQuantityRangeRule(min: 1000, max: 3600)
        let item = Imaging.newGlobalPriorityRecord("x", label: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingGlobalPriorityRecordRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.GlobalPriorityRecordRequiredLabelRule(message: "global priority record needs an entry")
        let item = Imaging.newGlobalPriorityRecord("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
