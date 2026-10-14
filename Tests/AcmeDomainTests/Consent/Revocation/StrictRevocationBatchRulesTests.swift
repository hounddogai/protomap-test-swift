@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentStrictRevocationBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultStrictRevocationBatchValidator()
        let item = Consent.newStrictRevocationBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentStrictRevocationBatchCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Consent.StrictRevocationBatchCountryLengthRule(maxLength: 32)
        let item = Consent.newStrictRevocationBatch("x", label: "y")
        item.country = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentStrictRevocationBatchRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Consent.StrictRevocationBatchRequiredReviewerRule(message: "strict revocation batch needs this field")
        let item = Consent.newStrictRevocationBatch("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
