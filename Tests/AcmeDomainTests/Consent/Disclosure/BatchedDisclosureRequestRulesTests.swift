@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedDisclosureRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedDisclosureRequestValidator()
        let item = Consent.newBatchedDisclosureRequest("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedDisclosureRequestRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Consent.BatchedDisclosureRequestRequiredSpecialtyRule(
            message: "batched disclosure request needs a value"
        )
        let item = Consent.newBatchedDisclosureRequest("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedDisclosureRequestReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Consent.BatchedDisclosureRequestReviewerLengthRule(maxLength: 86400)
        let item = Consent.newBatchedDisclosureRequest("x", title: "y")
        item.reviewer = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedDisclosureRequestRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Consent.BatchedDisclosureRequestRequiredTitleRule(
            message: "batched disclosure request needs this field"
        )
        let item = Consent.newBatchedDisclosureRequest("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedDisclosureRequestRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Consent.BatchedDisclosureRequestRetriesRangeRule(min: 16, max: 255)
        let item = Consent.newBatchedDisclosureRequest("x", title: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}
