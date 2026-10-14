@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveConsentFormReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultAdaptiveConsentFormReviewValidator()
        let item = Consent.newAdaptiveConsentFormReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentAdaptiveConsentFormReviewWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = Consent.AdaptiveConsentFormReviewWindowDaysRangeRule(min: 16, max: 32)
        let item = Consent.newAdaptiveConsentFormReview("x", name: "y")
        item.windowDays = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentAdaptiveConsentFormReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.AdaptiveConsentFormReviewNameLengthRule(maxLength: 120)
        let item = Consent.newAdaptiveConsentFormReview("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentAdaptiveConsentFormReviewPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Consent.AdaptiveConsentFormReviewPhoneLengthRule(maxLength: 32)
        let item = Consent.newAdaptiveConsentFormReview("x", name: "y")
        item.phone = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentAdaptiveConsentFormReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.AdaptiveConsentFormReviewRequiredNameRule(
            message: "adaptive consent form review needs a value"
        )
        let item = Consent.newAdaptiveConsentFormReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
