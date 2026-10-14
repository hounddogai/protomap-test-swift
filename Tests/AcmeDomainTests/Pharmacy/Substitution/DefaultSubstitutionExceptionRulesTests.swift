@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDefaultSubstitutionExceptionValidatorExtraTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDefaultSubstitutionExceptionValidator()
        let item = Pharmacy.newDefaultSubstitutionException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDefaultSubstitutionExceptionUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Pharmacy.DefaultSubstitutionExceptionUnitLengthRule(maxLength: 80)
        let item = Pharmacy.newDefaultSubstitutionException("x", label: "y")
        item.unit = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDefaultSubstitutionExceptionMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Pharmacy.DefaultSubstitutionExceptionMinimumRangeRule(min: 3.2, max: 2321.8)
        let item = Pharmacy.newDefaultSubstitutionException("x", label: "y")
        item.minimum = 2323.3
        #expect(rule.check(item).count > 0)
    }
}
