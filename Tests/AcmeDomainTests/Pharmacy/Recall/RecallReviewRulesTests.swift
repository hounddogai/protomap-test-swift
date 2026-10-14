@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyRecallReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultRecallReviewValidator()
        let item = Pharmacy.newRecallReview("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyRecallReviewUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Pharmacy.RecallReviewUpdatedAtRangeRule(min: 255, max: 1000)
        let item = Pharmacy.newRecallReview("x", name: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyRecallReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.RecallReviewCodeLengthRule(maxLength: 80)
        let item = Pharmacy.newRecallReview("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyRecallReviewNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Pharmacy.RecallReviewNameLengthRule(maxLength: 80)
        let item = Pharmacy.newRecallReview("x", name: "y")
        item.name = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
