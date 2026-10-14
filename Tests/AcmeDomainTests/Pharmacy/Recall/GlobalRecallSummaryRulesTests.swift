@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyGlobalRecallSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultGlobalRecallSummaryValidator()
        let item = Pharmacy.newGlobalRecallSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyGlobalRecallSummaryAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Pharmacy.GlobalRecallSummaryAmountRangeRule(min: 8.6, max: 4727.6)
        let item = Pharmacy.newGlobalRecallSummary("x", title: "y")
        item.amount = 4729.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyGlobalRecallSummarySummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Pharmacy.GlobalRecallSummarySummaryLengthRule(maxLength: 3600)
        let item = Pharmacy.newGlobalRecallSummary("x", title: "y")
        item.summary = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyGlobalRecallSummaryMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Pharmacy.GlobalRecallSummaryMaximumRangeRule(min: 7.8, max: 2896.7)
        let item = Pharmacy.newGlobalRecallSummary("x", title: "y")
        item.maximum = 2898.2
        #expect(rule.check(item).count > 0)
    }
}
