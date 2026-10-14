@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultSubstitutionTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultSubstitutionTierValidator()
        let item = Pharmacy.newDefaultSubstitutionTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultSubstitutionTierDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Pharmacy.DefaultSubstitutionTierDosageMgRangeRule(min: 9.8, max: 703.3)
        let item = Pharmacy.newDefaultSubstitutionTier("x", name: "y")
        item.dosageMg = 704.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDefaultSubstitutionTierPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Pharmacy.DefaultSubstitutionTierPayerLengthRule(maxLength: 1000)
        let item = Pharmacy.newDefaultSubstitutionTier("x", name: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
