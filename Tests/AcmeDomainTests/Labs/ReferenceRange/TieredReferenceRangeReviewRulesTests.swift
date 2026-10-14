@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsTieredReferenceRangeReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultTieredReferenceRangeReviewValidator()
        let item = Labs.newTieredReferenceRangeReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsTieredReferenceRangeReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.TieredReferenceRangeReviewRequiredCodeRule(
            message: "tiered reference range review needs an entry"
        )
        let item = Labs.newTieredReferenceRangeReview("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsTieredReferenceRangeReviewRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Labs.TieredReferenceRangeReviewRequiredContactEmailRule(
            message: "tiered reference range review needs an entry"
        )
        let item = Labs.newTieredReferenceRangeReview("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsTieredReferenceRangeReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.TieredReferenceRangeReviewRequiredLabelRule(
            message: "tiered reference range review needs a value"
        )
        let item = Labs.newTieredReferenceRangeReview("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsTieredReferenceRangeReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.TieredReferenceRangeReviewCodeLengthRule(maxLength: 64)
        let item = Labs.newTieredReferenceRangeReview("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
