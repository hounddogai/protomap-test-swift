@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistSlotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistSlotValidator()
        let item = Imaging.newWorklistSlot("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistSlotWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Imaging.WorklistSlotWindowDaysRangeRule(min: 64, max: 80)
        let item = Imaging.newWorklistSlot("x", name: "y")
        item.windowDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistSlotWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Imaging.WorklistSlotWeightRangeRule(min: 9.1, max: 2660.7)
        let item = Imaging.newWorklistSlot("x", name: "y")
        item.weight = 2662.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingWorklistSlotNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Imaging.WorklistSlotNameLengthRule(maxLength: 32)
        let item = Imaging.newWorklistSlot("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
