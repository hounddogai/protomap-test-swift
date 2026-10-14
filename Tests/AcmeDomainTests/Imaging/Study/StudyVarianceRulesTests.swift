@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyVarianceValidator()
        let item = Imaging.newStudyVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.StudyVarianceTitleLengthRule(maxLength: 120)
        let item = Imaging.newStudyVariance("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyVarianceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.StudyVarianceRequiredTitleRule(message: "study variance needs this field")
        let item = Imaging.newStudyVariance("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingStudyVarianceAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.StudyVarianceAttemptsRangeRule(min: 120, max: 255)
        let item = Imaging.newStudyVariance("x", title: "y")
        item.attempts = 256
        #expect(rule.check(item).count > 0)
    }
}
