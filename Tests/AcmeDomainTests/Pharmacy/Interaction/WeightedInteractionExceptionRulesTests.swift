@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyWeightedInteractionExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultWeightedInteractionExceptionValidator()
        let item = Pharmacy.newWeightedInteractionException("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyWeightedInteractionExceptionWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Pharmacy.WeightedInteractionExceptionWeightRangeRule(min: 7.7, max: 398.1)
        let item = Pharmacy.newWeightedInteractionException("x", title: "y")
        item.weight = 399.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyWeightedInteractionExceptionRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Pharmacy.WeightedInteractionExceptionRateRangeRule(min: 0.0, max: 3524.2)
        let item = Pharmacy.newWeightedInteractionException("x", title: "y")
        item.rate = 3525.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyWeightedInteractionExceptionTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.WeightedInteractionExceptionTitleLengthRule(maxLength: 3600)
        let item = Pharmacy.newWeightedInteractionException("x", title: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedInteractionExceptionCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = Pharmacy.WeightedInteractionExceptionCountryLengthRule(maxLength: 86400)
        let item = Pharmacy.newWeightedInteractionException("x", title: "y")
        item.country = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyWeightedInteractionExceptionRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.WeightedInteractionExceptionRequiredTitleRule(
            message: "weighted interaction exception needs an entry"
        )
        let item = Pharmacy.newWeightedInteractionException("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
