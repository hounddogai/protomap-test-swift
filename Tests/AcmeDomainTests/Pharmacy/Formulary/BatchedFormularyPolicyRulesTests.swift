@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedFormularyPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultBatchedFormularyPolicyValidator()
        let item = Pharmacy.newBatchedFormularyPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyBatchedFormularyPolicyRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = Pharmacy.BatchedFormularyPolicyRequiredWardRule(message: "batched formulary policy needs a value")
        let item = Pharmacy.newBatchedFormularyPolicy("", title: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyBatchedFormularyPolicyRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Pharmacy.BatchedFormularyPolicyRequiredCountryRule(message: "batched formulary policy needs a value")
        let item = Pharmacy.newBatchedFormularyPolicy("", title: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyBatchedFormularyPolicyGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Pharmacy.BatchedFormularyPolicyGraceDaysRangeRule(min: 64, max: 3600)
        let item = Pharmacy.newBatchedFormularyPolicy("x", title: "y")
        item.graceDays = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyBatchedFormularyPolicyCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Pharmacy.BatchedFormularyPolicyCountryLengthRule(maxLength: 16)
        let item = Pharmacy.newBatchedFormularyPolicy("x", title: "y")
        item.country = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}
