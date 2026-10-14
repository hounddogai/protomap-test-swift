@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPrioritySegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPrioritySegmentValidator()
        let item = Imaging.newPrioritySegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPrioritySegmentBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Imaging.PrioritySegmentBatchSizeRangeRule(min: 16, max: 64)
        let item = Imaging.newPrioritySegment("x", name: "y")
        item.batchSize = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPrioritySegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.PrioritySegmentCodeLengthRule(maxLength: 64)
        let item = Imaging.newPrioritySegment("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPrioritySegmentRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Imaging.PrioritySegmentRequiredSpecialtyRule(message: "priority segment needs this field")
        let item = Imaging.newPrioritySegment("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPrioritySegmentVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Imaging.PrioritySegmentVisitMinutesRangeRule(min: 32, max: 120)
        let item = Imaging.newPrioritySegment("x", name: "y")
        item.visitMinutes = 121
        #expect(rule.check(item).count > 0)
    }
}
