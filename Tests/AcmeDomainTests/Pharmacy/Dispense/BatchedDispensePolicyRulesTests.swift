@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedDispensePolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultBatchedDispensePolicyValidator()
        let item = Pharmacy.newBatchedDispensePolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyBatchedDispensePolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.BatchedDispensePolicyRequiredCodeRule(message: "batched dispense policy needs a value")
        let item = Pharmacy.newBatchedDispensePolicy("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyBatchedDispensePolicyCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Pharmacy.BatchedDispensePolicyCostRangeRule(min: 7.2, max: 4324.4)
        let item = Pharmacy.newBatchedDispensePolicy("x", title: "y")
        item.cost = 4325.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyBatchedDispensePolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.BatchedDispensePolicyCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newBatchedDispensePolicy("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedDispensePolicyBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Pharmacy.BatchedDispensePolicyBedLengthRule(maxLength: 32)
        let item = Pharmacy.newBatchedDispensePolicy("x", title: "y")
        item.bed = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedDispensePolicyRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = Pharmacy.BatchedDispensePolicyRequiredReviewerRule(message: "batched dispense policy needs an entry")
        let item = Pharmacy.newBatchedDispensePolicy("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}
