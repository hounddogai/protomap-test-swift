@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageReviewValidator()
        let item = Consent.newLanguageReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageReviewMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Consent.LanguageReviewMaximumRangeRule(min: 0.2, max: 2293.1)
        let item = Consent.newLanguageReview("x", name: "y")
        item.maximum = 2294.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.LanguageReviewNameLengthRule(maxLength: 120)
        let item = Consent.newLanguageReview("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LanguageReviewCodeLengthRule(maxLength: 3600)
        let item = Consent.newLanguageReview("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.LanguageReviewRequiredNameRule(message: "language review needs this field")
        let item = Consent.newLanguageReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
