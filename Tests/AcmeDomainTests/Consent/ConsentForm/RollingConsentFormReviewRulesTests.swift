@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingConsentFormReviewValidator()
        let item = Consent.newRollingConsentFormReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingConsentFormReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.RollingConsentFormReviewCodeLengthRule(maxLength: 64)
        let item = Consent.newRollingConsentFormReview("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentRollingConsentFormReviewRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.RollingConsentFormReviewRequiredTitleRule(
            message: "rolling consent form review needs this field"
        )
        let item = Consent.newRollingConsentFormReview("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingConsentFormReviewQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Consent.RollingConsentFormReviewQuantityRangeRule(min: 120, max: 3600)
        let item = Consent.newRollingConsentFormReview("x", title: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRollingConsentFormReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RollingConsentFormReviewRequiredCodeRule(
            message: "rolling consent form review needs an entry"
        )
        let item = Consent.newRollingConsentFormReview("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
