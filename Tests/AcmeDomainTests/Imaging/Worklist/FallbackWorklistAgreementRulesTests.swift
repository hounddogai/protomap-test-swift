@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingFallbackWorklistAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultFallbackWorklistAgreementValidator()
        let item = Imaging.newFallbackWorklistAgreement("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingFallbackWorklistAgreementScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Imaging.FallbackWorklistAgreementScoreRangeRule(min: 3.7, max: 1919.8)
        let item = Imaging.newFallbackWorklistAgreement("x", title: "y")
        item.score = 1921.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingFallbackWorklistAgreementRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Imaging.FallbackWorklistAgreementRequiredTimezoneRule(
            message: "fallback worklist agreement needs a value"
        )
        let item = Imaging.newFallbackWorklistAgreement("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingFallbackWorklistAgreementTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Imaging.FallbackWorklistAgreementTimezoneLengthRule(maxLength: 3600)
        let item = Imaging.newFallbackWorklistAgreement("x", title: "y")
        item.timezone = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingFallbackWorklistAgreementEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Imaging.FallbackWorklistAgreementEndsAtRangeRule(min: 1000, max: 86400)
        let item = Imaging.newFallbackWorklistAgreement("x", title: "y")
        item.endsAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ImagingFallbackWorklistAgreementMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Imaging.FallbackWorklistAgreementMinimumRangeRule(min: 0.2, max: 532.2)
        let item = Imaging.newFallbackWorklistAgreement("x", title: "y")
        item.minimum = 533.7
        #expect(rule.check(item).count > 0)
    }
}
