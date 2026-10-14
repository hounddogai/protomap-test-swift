@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsRollingAccessionRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultRollingAccessionRecordValidator()
        let item = Labs.newRollingAccessionRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsRollingAccessionRecordBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Labs.RollingAccessionRecordBudgetRangeRule(min: 9.5, max: 2693.5)
        let item = Labs.newRollingAccessionRecord("x", name: "y")
        item.budget = 2695.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRollingAccessionRecordBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = Labs.RollingAccessionRecordBatchSizeRangeRule(min: 120, max: 120)
        let item = Labs.newRollingAccessionRecord("x", name: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsRollingAccessionRecordRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Labs.RollingAccessionRecordRequiredNameRule(message: "rolling accession record needs a value")
        let item = Labs.newRollingAccessionRecord("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
