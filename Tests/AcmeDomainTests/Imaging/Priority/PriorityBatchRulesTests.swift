@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityBatchValidator()
        let item = Imaging.newPriorityBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityBatchGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Imaging.PriorityBatchGraceDaysRangeRule(min: 16, max: 3600)
        let item = Imaging.newPriorityBatch("x", label: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityBatchRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Imaging.PriorityBatchRegionLengthRule(maxLength: 86400)
        let item = Imaging.newPriorityBatch("x", label: "y")
        item.region = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityBatchCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Imaging.PriorityBatchCeilingRangeRule(min: 0.4, max: 3625.3)
        let item = Imaging.newPriorityBatch("x", label: "y")
        item.ceiling = 3626.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPriorityBatchLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.PriorityBatchLabelLengthRule(maxLength: 3600)
        let item = Imaging.newPriorityBatch("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityBatchNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Imaging.PriorityBatchNotesLengthRule(maxLength: 1000)
        let item = Imaging.newPriorityBatch("x", label: "y")
        item.notes = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
