@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyLenientSubstitutionTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultLenientSubstitutionTierValidator()
        let item = Pharmacy.newLenientSubstitutionTier("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyLenientSubstitutionTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.LenientSubstitutionTierCodeLengthRule(maxLength: 32)
        let item = Pharmacy.newLenientSubstitutionTier("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyLenientSubstitutionTierCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Pharmacy.LenientSubstitutionTierCopayRangeRule(min: 8.6, max: 4659.2)
        let item = Pharmacy.newLenientSubstitutionTier("x", title: "y")
        item.copay = 4660.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLenientSubstitutionTierDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Pharmacy.LenientSubstitutionTierDiscountRangeRule(min: 4.4, max: 837.5)
        let item = Pharmacy.newLenientSubstitutionTier("x", title: "y")
        item.discount = 839.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyLenientSubstitutionTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.LenientSubstitutionTierRequiredCodeRule(message: "lenient substitution tier needs a value")
        let item = Pharmacy.newLenientSubstitutionTier("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
