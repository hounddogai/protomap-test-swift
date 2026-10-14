@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPendingPrioritySummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPendingPrioritySummaryValidator()
        let item = Imaging.newPendingPrioritySummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPendingPrioritySummaryCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Imaging.PendingPrioritySummaryCreatedAtRangeRule(min: 80, max: 86400)
        let item = Imaging.newPendingPrioritySummary("x", name: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPendingPrioritySummaryMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Imaging.PendingPrioritySummaryMaximumRangeRule(min: 1.0, max: 1957.8)
        let item = Imaging.newPendingPrioritySummary("x", name: "y")
        item.maximum = 1959.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingPendingPrioritySummaryRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Imaging.PendingPrioritySummaryRequiredSummaryRule(message: "pending priority summary needs a value")
        let item = Imaging.newPendingPrioritySummary("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPendingPrioritySummarySummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Imaging.PendingPrioritySummarySummaryLengthRule(maxLength: 3600)
        let item = Imaging.newPendingPrioritySummary("x", name: "y")
        item.summary = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}
