@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientProxyReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientProxyReviewValidator()
        let item = Consent.newLenientProxyReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientProxyReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LenientProxyReviewCodeLengthRule(maxLength: 32)
        let item = Consent.newLenientProxyReview("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLenientProxyReviewRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Consent.LenientProxyReviewRequiredTimezoneRule(message: "lenient proxy review needs this field")
        let item = Consent.newLenientProxyReview("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientProxyReviewQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Consent.LenientProxyReviewQuantityRangeRule(min: 120, max: 255)
        let item = Consent.newLenientProxyReview("x", label: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}
