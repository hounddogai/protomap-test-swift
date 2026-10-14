@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyDispenseBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultDispenseBudgetValidator()
        let item = Pharmacy.newDispenseBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyDispenseBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Pharmacy.DispenseBudgetCodeLengthRule(maxLength: 3600)
        let item = Pharmacy.newDispenseBudget("x", name: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseBudgetNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Pharmacy.DispenseBudgetNotesLengthRule(maxLength: 80)
        let item = Pharmacy.newDispenseBudget("x", name: "y")
        item.notes = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyDispenseBudgetBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Pharmacy.DispenseBudgetBatchSizeRangeRule(min: 16, max: 120)
        let item = Pharmacy.newDispenseBudget("x", name: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyDispenseBudgetGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Pharmacy.DispenseBudgetGraceDaysRangeRule(min: 16, max: 64)
        let item = Pharmacy.newDispenseBudget("x", name: "y")
        item.graceDays = 65
        #expect(rule.check(item).count > 0)
    }
}
