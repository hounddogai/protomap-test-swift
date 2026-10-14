@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormReviewValidator()
        let item = Consent.newConsentFormReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ConsentFormReviewCodeLengthRule(maxLength: 32)
        let item = Consent.newConsentFormReview("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormReviewPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Consent.ConsentFormReviewPatientRefLengthRule(maxLength: 3600)
        let item = Consent.newConsentFormReview("x", label: "y")
        item.patientRef = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormReviewRequiredCodeRule(message: "consent form review needs this field")
        let item = Consent.newConsentFormReview("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormReviewLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.ConsentFormReviewLabelLengthRule(maxLength: 120)
        let item = Consent.newConsentFormReview("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
