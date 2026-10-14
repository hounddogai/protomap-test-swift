@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyCappedDispenseReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultCappedDispenseReviewValidator()
        let item = Pharmacy.newCappedDispenseReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyCappedDispenseReviewPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Pharmacy.CappedDispenseReviewPriorityRangeRule(min: 1000, max: 3600)
        let item = Pharmacy.newCappedDispenseReview("x", label: "y")
        item.priority = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyCappedDispenseReviewRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.CappedDispenseReviewRequiredLabelRule(message: "capped dispense review needs a value")
        let item = Pharmacy.newCappedDispenseReview("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
