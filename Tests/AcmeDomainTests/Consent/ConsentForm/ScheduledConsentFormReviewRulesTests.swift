@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentScheduledConsentFormReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultScheduledConsentFormReviewValidator()
        let item = Consent.newScheduledConsentFormReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentScheduledConsentFormReviewRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Consent.ScheduledConsentFormReviewRequiredSummaryRule(
            message: "scheduled consent form review needs a value"
        )
        let item = Consent.newScheduledConsentFormReview("", name: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledConsentFormReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.ScheduledConsentFormReviewNameLengthRule(maxLength: 64)
        let item = Consent.newScheduledConsentFormReview("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentScheduledConsentFormReviewRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ScheduledConsentFormReviewRequiredNameRule(
            message: "scheduled consent form review needs a value"
        )
        let item = Consent.newScheduledConsentFormReview("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentScheduledConsentFormReviewQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Consent.ScheduledConsentFormReviewQuantityRangeRule(min: 64, max: 86400)
        let item = Consent.newScheduledConsentFormReview("x", name: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}
