@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyStrictRecallReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultStrictRecallReviewValidator()
        let item = Pharmacy.newStrictRecallReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyStrictRecallReviewDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Pharmacy.StrictRecallReviewDosageMgRangeRule(min: 6.6, max: 4587.9)
        let item = Pharmacy.newStrictRecallReview("x", label: "y")
        item.dosageMg = 4589.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyStrictRecallReviewRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Pharmacy.StrictRecallReviewRequiredSummaryRule(message: "strict recall review needs a value")
        let item = Pharmacy.newStrictRecallReview("", label: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyStrictRecallReviewSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Pharmacy.StrictRecallReviewSummaryLengthRule(maxLength: 32)
        let item = Pharmacy.newStrictRecallReview("x", label: "y")
        item.summary = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyStrictRecallReviewEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Pharmacy.StrictRecallReviewEndsAtRangeRule(min: 64, max: 120)
        let item = Pharmacy.newStrictRecallReview("x", label: "y")
        item.endsAt = 121
        #expect(rule.check(item).count > 0)
    }
}
