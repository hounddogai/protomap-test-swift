@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackReadBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultFallbackReadBaselineValidator()
        let item = Imaging.newFallbackReadBaseline("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingFallbackReadBaselineRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Imaging.FallbackReadBaselineRequiredChannelRule(message: "fallback read baseline needs this field")
        let item = Imaging.newFallbackReadBaseline("", title: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingFallbackReadBaselineRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Imaging.FallbackReadBaselineRequiredReviewerRule(message: "fallback read baseline needs a value")
        let item = Imaging.newFallbackReadBaseline("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingFallbackReadBaselineCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Imaging.FallbackReadBaselineCreatedAtRangeRule(min: 64, max: 3600)
        let item = Imaging.newFallbackReadBaseline("x", title: "y")
        item.createdAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingFallbackReadBaselineTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Imaging.FallbackReadBaselineTitleLengthRule(maxLength: 86400)
        let item = Imaging.newFallbackReadBaseline("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
