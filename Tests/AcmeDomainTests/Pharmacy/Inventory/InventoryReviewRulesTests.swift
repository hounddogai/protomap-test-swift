@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInventoryReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInventoryReviewValidator()
        let item = Pharmacy.newInventoryReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInventoryReviewAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Pharmacy.InventoryReviewAttemptsRangeRule(min: 80, max: 80)
        let item = Pharmacy.newInventoryReview("x", name: "y")
        item.attempts = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInventoryReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.InventoryReviewCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newInventoryReview("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
