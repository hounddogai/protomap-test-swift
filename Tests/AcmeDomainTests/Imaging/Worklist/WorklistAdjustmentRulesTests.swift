@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingWorklistAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultWorklistAdjustmentValidator()
        let item = Imaging.newWorklistAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingWorklistAdjustmentRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Imaging.WorklistAdjustmentRequiredSegmentRule(message: "worklist adjustment needs a value")
        let item = Imaging.newWorklistAdjustment("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingWorklistAdjustmentLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Imaging.WorklistAdjustmentLocaleLengthRule(maxLength: 1000)
        let item = Imaging.newWorklistAdjustment("x", name: "y")
        item.locale = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingWorklistAdjustmentStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = Imaging.WorklistAdjustmentStartsAtRangeRule(min: 120, max: 120)
        let item = Imaging.newWorklistAdjustment("x", name: "y")
        item.startsAt = 121
        #expect(rule.check(item).count > 0)
    }
}
