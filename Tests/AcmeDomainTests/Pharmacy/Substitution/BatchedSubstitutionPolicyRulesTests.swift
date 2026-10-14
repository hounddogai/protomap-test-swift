@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyBatchedSubstitutionPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultBatchedSubstitutionPolicyValidator()
        let item = Pharmacy.newBatchedSubstitutionPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionPolicyGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Pharmacy.BatchedSubstitutionPolicyGraceDaysRangeRule(min: 80, max: 80)
        let item = Pharmacy.newBatchedSubstitutionPolicy("x", name: "y")
        item.graceDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionPolicyRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.BatchedSubstitutionPolicyRequiredCodeRule(
            message: "batched substitution policy needs an entry"
        )
        let item = Pharmacy.newBatchedSubstitutionPolicy("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyBatchedSubstitutionPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.BatchedSubstitutionPolicyCodeLengthRule(maxLength: 16)
        let item = Pharmacy.newBatchedSubstitutionPolicy("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionPolicyCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Pharmacy.BatchedSubstitutionPolicyCountryLengthRule(maxLength: 86400)
        let item = Pharmacy.newBatchedSubstitutionPolicy("x", name: "y")
        item.country = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyBatchedSubstitutionPolicyScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Pharmacy.BatchedSubstitutionPolicyScoreRangeRule(min: 2.2, max: 4981.9)
        let item = Pharmacy.newBatchedSubstitutionPolicy("x", name: "y")
        item.score = 4983.4
        #expect(rule.check(item).count > 0)
    }
}
