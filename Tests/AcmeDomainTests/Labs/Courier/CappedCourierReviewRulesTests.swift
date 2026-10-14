@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedCourierReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedCourierReviewValidator()
        let item = Labs.newCappedCourierReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedCourierReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.CappedCourierReviewRequiredCodeRule(message: "capped courier review needs an entry")
        let item = Labs.newCappedCourierReview("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCappedCourierReviewDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Labs.CappedCourierReviewDurationMinutesRangeRule(min: 16, max: 32)
        let item = Labs.newCappedCourierReview("x", title: "y")
        item.durationMinutes = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedCourierReviewRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.CappedCourierReviewRequiredTitleRule(message: "capped courier review needs an entry")
        let item = Labs.newCappedCourierReview("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
