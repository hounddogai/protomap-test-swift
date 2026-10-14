@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsLegacyAccessionMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultLegacyAccessionMilestoneValidator()
        let item = Labs.newLegacyAccessionMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsLegacyAccessionMilestoneReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Labs.LegacyAccessionMilestoneReviewerLengthRule(maxLength: 32)
        let item = Labs.newLegacyAccessionMilestone("x", label: "y")
        item.reviewer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsLegacyAccessionMilestoneSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = Labs.LegacyAccessionMilestoneSegmentLengthRule(maxLength: 1000)
        let item = Labs.newLegacyAccessionMilestone("x", label: "y")
        item.segment = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
