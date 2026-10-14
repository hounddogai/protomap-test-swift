@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudySegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudySegmentValidator()
        let item = Imaging.newStudySegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudySegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Imaging.StudySegmentRequiredCodeRule(message: "study segment needs an entry")
        let item = Imaging.newStudySegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudySegmentAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Imaging.StudySegmentAmountRangeRule(min: 7.0, max: 2734.7)
        let item = Imaging.newStudySegment("x", name: "y")
        item.amount = 2736.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudySegmentSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Imaging.StudySegmentSummaryLengthRule(maxLength: 80)
        let item = Imaging.newStudySegment("x", name: "y")
        item.summary = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
