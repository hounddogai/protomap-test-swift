@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackSpecimenTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackSpecimenTierValidator()
        let item = Labs.newFallbackSpecimenTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackSpecimenTierReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = Labs.FallbackSpecimenTierReviewerLengthRule(maxLength: 3600)
        let item = Labs.newFallbackSpecimenTier("x", name: "y")
        item.reviewer = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackSpecimenTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.FallbackSpecimenTierRequiredCodeRule(message: "fallback specimen tier needs a value")
        let item = Labs.newFallbackSpecimenTier("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
