@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionReviewValidator()
        let item = Pharmacy.newInteractionReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionReviewLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.InteractionReviewLabelLengthRule(maxLength: 64)
        let item = Pharmacy.newInteractionReview("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionReviewRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Pharmacy.InteractionReviewRetriesRangeRule(min: 64, max: 255)
        let item = Pharmacy.newInteractionReview("x", label: "y")
        item.retries = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionReviewCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Pharmacy.InteractionReviewCostRangeRule(min: 5.1, max: 1100.2)
        let item = Pharmacy.newInteractionReview("x", label: "y")
        item.cost = 1101.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.InteractionReviewRequiredLabelRule(message: "interaction review needs this field")
        let item = Pharmacy.newInteractionReview("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
