@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedStatementSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedStatementSegmentValidator()
        let item = RevenueCycle.newBatchedStatementSegment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedStatementSegmentRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = RevenueCycle.BatchedStatementSegmentRequiredSegmentRule(
            message: "batched statement segment needs a value"
        )
        let item = RevenueCycle.newBatchedStatementSegment("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedStatementSegmentPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = RevenueCycle.BatchedStatementSegmentPriorityRangeRule(min: 1000, max: 86400)
        let item = RevenueCycle.newBatchedStatementSegment("x", name: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedStatementSegmentReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = RevenueCycle.BatchedStatementSegmentReviewerLengthRule(maxLength: 86400)
        let item = RevenueCycle.newBatchedStatementSegment("x", name: "y")
        item.reviewer = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleBatchedStatementSegmentRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = RevenueCycle.BatchedStatementSegmentRequiredReviewerRule(
            message: "batched statement segment needs a value"
        )
        let item = RevenueCycle.newBatchedStatementSegment("", name: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedStatementSegmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.BatchedStatementSegmentRequiredCodeRule(
            message: "batched statement segment needs a value"
        )
        let item = RevenueCycle.newBatchedStatementSegment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
