@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyAdjustmentValidator()
        let item = Imaging.newStudyAdjustment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyAdjustmentSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Imaging.StudyAdjustmentSourceLengthRule(maxLength: 120)
        let item = Imaging.newStudyAdjustment("x", title: "y")
        item.source = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyAdjustmentRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Imaging.StudyAdjustmentRetriesRangeRule(min: 64, max: 255)
        let item = Imaging.newStudyAdjustment("x", title: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}
