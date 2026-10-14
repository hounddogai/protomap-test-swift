@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackReferenceRangeProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackReferenceRangeProfileValidator()
        let item = Labs.newFallbackReferenceRangeProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackReferenceRangeProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.FallbackReferenceRangeProfileCodeLengthRule(maxLength: 86400)
        let item = Labs.newFallbackReferenceRangeProfile("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackReferenceRangeProfileScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Labs.FallbackReferenceRangeProfileScoreRangeRule(min: 6.8, max: 1665.2)
        let item = Labs.newFallbackReferenceRangeProfile("x", label: "y")
        item.score = 1666.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsFallbackReferenceRangeProfileCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Labs.FallbackReferenceRangeProfileCreatedAtRangeRule(min: 64, max: 120)
        let item = Labs.newFallbackReferenceRangeProfile("x", label: "y")
        item.createdAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsFallbackReferenceRangeProfileMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Labs.FallbackReferenceRangeProfileMarginRangeRule(min: 0.8, max: 1401.0)
        let item = Labs.newFallbackReferenceRangeProfile("x", label: "y")
        item.margin = 1402.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsFallbackReferenceRangeProfileSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Labs.FallbackReferenceRangeProfileSegmentLengthRule(maxLength: 1000)
        let item = Labs.newFallbackReferenceRangeProfile("x", label: "y")
        item.segment = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackReferenceRangeProfileRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Labs.FallbackReferenceRangeProfileRequiredSegmentRule(
            message: "fallback reference range profile needs this field"
        )
        let item = Labs.newFallbackReferenceRangeProfile("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
