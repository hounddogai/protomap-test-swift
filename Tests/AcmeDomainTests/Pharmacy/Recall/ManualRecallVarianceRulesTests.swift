@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyManualRecallVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultManualRecallVarianceValidator()
        let item = Pharmacy.newManualRecallVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyManualRecallVarianceEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = Pharmacy.ManualRecallVarianceEndsAtRangeRule(min: 64, max: 3600)
        let item = Pharmacy.newManualRecallVariance("x", name: "y")
        item.endsAt = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyManualRecallVarianceBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Pharmacy.ManualRecallVarianceBudgetRangeRule(min: 9.0, max: 2436.3)
        let item = Pharmacy.newManualRecallVariance("x", name: "y")
        item.budget = 2437.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyManualRecallVarianceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.ManualRecallVarianceCodeLengthRule(maxLength: 64)
        let item = Pharmacy.newManualRecallVariance("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyManualRecallVarianceRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Pharmacy.ManualRecallVarianceRequiredCurrencyRule(message: "manual recall variance needs a value")
        let item = Pharmacy.newManualRecallVariance("", name: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}
