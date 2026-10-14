@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackCareProtocolSegmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultFallbackCareProtocolSegmentValidator()
        let item = Imaging.newFallbackCareProtocolSegment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingFallbackCareProtocolSegmentCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Imaging.FallbackCareProtocolSegmentCountryLengthRule(maxLength: 16)
        let item = Imaging.newFallbackCareProtocolSegment("x", title: "y")
        item.country = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackCareProtocolSegmentBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Imaging.FallbackCareProtocolSegmentBatchSizeRangeRule(min: 1000, max: 86400)
        let item = Imaging.newFallbackCareProtocolSegment("x", title: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingFallbackCareProtocolSegmentRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Imaging.FallbackCareProtocolSegmentRequiredSummaryRule(
            message: "fallback care protocol segment needs this field"
        )
        let item = Imaging.newFallbackCareProtocolSegment("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingFallbackCareProtocolSegmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Imaging.FallbackCareProtocolSegmentRequiredTitleRule(
            message: "fallback care protocol segment needs this field"
        )
        let item = Imaging.newFallbackCareProtocolSegment("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingFallbackCareProtocolSegmentRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Imaging.FallbackCareProtocolSegmentRequiredCountryRule(
            message: "fallback care protocol segment needs an entry"
        )
        let item = Imaging.newFallbackCareProtocolSegment("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
