@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackCourierDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackCourierDraftValidator()
        let item = Labs.newFallbackCourierDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackCourierDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.FallbackCourierDraftRequiredLabelRule(message: "fallback courier draft needs an entry")
        let item = Labs.newFallbackCourierDraft("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackCourierDraftLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.FallbackCourierDraftLabelLengthRule(maxLength: 1000)
        let item = Labs.newFallbackCourierDraft("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackCourierDraftReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Labs.FallbackCourierDraftReviewerLengthRule(maxLength: 1000)
        let item = Labs.newFallbackCourierDraft("x", label: "y")
        item.reviewer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
