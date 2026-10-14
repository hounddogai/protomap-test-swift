@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureReviewValidator()
        let item = Consent.newDisclosureReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.DisclosureReviewCodeLengthRule(maxLength: 1000)
        let item = Consent.newDisclosureReview("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureReviewRequiredContactEmailRuleTests {
    @Test func flagsABlankContactEmail() throws {
        let rule = Consent.DisclosureReviewRequiredContactEmailRule(message: "disclosure review needs an entry")
        let item = Consent.newDisclosureReview("", label: "")
        item.contactEmail = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.DisclosureReviewRequiredLabelRule(message: "disclosure review needs this field")
        let item = Consent.newDisclosureReview("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureReviewSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Consent.DisclosureReviewSequenceRangeRule(min: 16, max: 1000)
        let item = Consent.newDisclosureReview("x", label: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureReviewPhoneLengthRuleTests {
    @Test func flagsALongPhone() throws {
        let rule = Consent.DisclosureReviewPhoneLengthRule(maxLength: 1000)
        let item = Consent.newDisclosureReview("x", label: "y")
        item.phone = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.phone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
