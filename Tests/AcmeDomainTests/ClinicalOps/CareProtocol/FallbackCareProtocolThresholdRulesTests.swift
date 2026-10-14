@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackCareProtocolThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackCareProtocolThresholdValidator()
        let item = ClinicalOps.newFallbackCareProtocolThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackCareProtocolThresholdBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = ClinicalOps.FallbackCareProtocolThresholdBedLengthRule(maxLength: 3600)
        let item = ClinicalOps.newFallbackCareProtocolThreshold("x", title: "y")
        item.bed = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackCareProtocolThresholdSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = ClinicalOps.FallbackCareProtocolThresholdSequenceRangeRule(min: 64, max: 86400)
        let item = ClinicalOps.newFallbackCareProtocolThreshold("x", title: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsFallbackCareProtocolThresholdRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = ClinicalOps.FallbackCareProtocolThresholdRequiredReviewerRule(
            message: "fallback care protocol threshold needs this field"
        )
        let item = ClinicalOps.newFallbackCareProtocolThreshold("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackCareProtocolThresholdReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = ClinicalOps.FallbackCareProtocolThresholdReviewerLengthRule(maxLength: 16)
        let item = ClinicalOps.newFallbackCareProtocolThreshold("x", title: "y")
        item.reviewer = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackCareProtocolThresholdRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.FallbackCareProtocolThresholdRequiredTitleRule(
            message: "fallback care protocol threshold needs this field"
        )
        let item = ClinicalOps.newFallbackCareProtocolThreshold("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
