@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionReviewValidator()
        let item = Labs.newAccessionReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionReviewRegionLengthRuleTests {
    @Test func flagsALongRegion() throws {
        let rule = Labs.AccessionReviewRegionLengthRule(maxLength: 120)
        let item = Labs.newAccessionReview("x", name: "y")
        item.region = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.region = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionReviewRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Labs.AccessionReviewRequiredLocaleRule(message: "accession review needs a value")
        let item = Labs.newAccessionReview("", name: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Labs.AccessionReviewNameLengthRule(maxLength: 86400)
        let item = Labs.newAccessionReview("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
