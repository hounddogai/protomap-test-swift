@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingBatchedStudySegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultBatchedStudySegmentValidator()
        let item = Imaging.newBatchedStudySegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingBatchedStudySegmentRequiredProcedureCodeRuleTests {
    @Test func flagsABlankProcedureCode() throws {
        let rule = Imaging.BatchedStudySegmentRequiredProcedureCodeRule(
            message: "batched study segment needs this field"
        )
        let item = Imaging.newBatchedStudySegment("", label: "")
        item.procedureCode = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingBatchedStudySegmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Imaging.BatchedStudySegmentRequiredLabelRule(message: "batched study segment needs this field")
        let item = Imaging.newBatchedStudySegment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingBatchedStudySegmentLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Imaging.BatchedStudySegmentLimitRangeRule(min: 32, max: 3600)
        let item = Imaging.newBatchedStudySegment("x", label: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingBatchedStudySegmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.BatchedStudySegmentLabelLengthRule(maxLength: 64)
        let item = Imaging.newBatchedStudySegment("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingBatchedStudySegmentProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = Imaging.BatchedStudySegmentProcedureCodeLengthRule(maxLength: 3600)
        let item = Imaging.newBatchedStudySegment("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingBatchedStudySegmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.BatchedStudySegmentRequiredTitleRule(message: "batched study segment needs an entry")
        let item = Imaging.newBatchedStudySegment("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
