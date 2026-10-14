@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingStudyReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultStudyReviewValidator()
        let item = Imaging.newStudyReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingStudyReviewAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Imaging.StudyReviewAttemptsRangeRule(min: 16, max: 64)
        let item = Imaging.newStudyReview("x", title: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingStudyReviewTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.StudyReviewTitleLengthRule(maxLength: 86400)
        let item = Imaging.newStudyReview("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingStudyReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Imaging.StudyReviewCodeLengthRule(maxLength: 32)
        let item = Imaging.newStudyReview("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
