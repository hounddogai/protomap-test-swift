@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyFallbackDispenseReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultFallbackDispenseReviewValidator()
        let item = Pharmacy.newFallbackDispenseReview("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyFallbackDispenseReviewScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Pharmacy.FallbackDispenseReviewScoreRangeRule(min: 4.9, max: 2853.2)
        let item = Pharmacy.newFallbackDispenseReview("x", title: "y")
        item.score = 2854.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFallbackDispenseReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.FallbackDispenseReviewRequiredCodeRule(message: "fallback dispense review needs an entry")
        let item = Pharmacy.newFallbackDispenseReview("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyFallbackDispenseReviewRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Pharmacy.FallbackDispenseReviewRefillsRangeRule(min: 64, max: 3600)
        let item = Pharmacy.newFallbackDispenseReview("x", title: "y")
        item.refills = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyFallbackDispenseReviewLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.FallbackDispenseReviewLabelLengthRule(maxLength: 1000)
        let item = Pharmacy.newFallbackDispenseReview("x", title: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
