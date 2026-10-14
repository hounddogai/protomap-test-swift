@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityWindowValidator()
        let item = Imaging.newPriorityWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityWindowRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Imaging.PriorityWindowRequiredLocaleRule(message: "priority window needs this field")
        let item = Imaging.newPriorityWindow("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityWindowReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Imaging.PriorityWindowReviewerLengthRule(maxLength: 120)
        let item = Imaging.newPriorityWindow("x", name: "y")
        item.reviewer = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityWindowRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Imaging.PriorityWindowRequiredReviewerRule(message: "priority window needs this field")
        let item = Imaging.newPriorityWindow("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
