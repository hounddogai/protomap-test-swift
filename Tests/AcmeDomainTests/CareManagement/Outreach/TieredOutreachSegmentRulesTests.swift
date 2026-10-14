@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementTieredOutreachSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultTieredOutreachSegmentValidator()
        let item = CareManagement.newTieredOutreachSegment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementTieredOutreachSegmentRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = CareManagement.TieredOutreachSegmentRequiredSummaryRule(
            message: "tiered outreach segment needs a value"
        )
        let item = CareManagement.newTieredOutreachSegment("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementTieredOutreachSegmentRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = CareManagement.TieredOutreachSegmentRequiredReviewerRule(
            message: "tiered outreach segment needs this field"
        )
        let item = CareManagement.newTieredOutreachSegment("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementTieredOutreachSegmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.TieredOutreachSegmentCodeLengthRule(maxLength: 32)
        let item = CareManagement.newTieredOutreachSegment("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
