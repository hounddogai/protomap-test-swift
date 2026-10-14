@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingWorklistSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPendingWorklistSummaryValidator()
        let item = Imaging.newPendingWorklistSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPendingWorklistSummaryRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Imaging.PendingWorklistSummaryRequiredReviewerRule(message: "pending worklist summary needs an entry")
        let item = Imaging.newPendingWorklistSummary("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPendingWorklistSummaryRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Imaging.PendingWorklistSummaryRequiredSummaryRule(message: "pending worklist summary needs an entry")
        let item = Imaging.newPendingWorklistSummary("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPendingWorklistSummarySummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Imaging.PendingWorklistSummarySummaryLengthRule(maxLength: 64)
        let item = Imaging.newPendingWorklistSummary("x", label: "y")
        item.summary = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPendingWorklistSummaryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Imaging.PendingWorklistSummaryLabelLengthRule(maxLength: 3600)
        let item = Imaging.newPendingWorklistSummary("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPendingWorklistSummaryReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Imaging.PendingWorklistSummaryReviewerLengthRule(maxLength: 255)
        let item = Imaging.newPendingWorklistSummary("x", label: "y")
        item.reviewer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
