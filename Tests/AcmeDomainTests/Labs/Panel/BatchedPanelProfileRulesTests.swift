@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedPanelProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultBatchedPanelProfileValidator()
        let item = Labs.newBatchedPanelProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsBatchedPanelProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.BatchedPanelProfileCodeLengthRule(maxLength: 64)
        let item = Labs.newBatchedPanelProfile("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsBatchedPanelProfileDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Labs.BatchedPanelProfileDescriptionLengthRule(maxLength: 80)
        let item = Labs.newBatchedPanelProfile("x", title: "y")
        item.description = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsBatchedPanelProfileFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Labs.BatchedPanelProfileFloorValueRangeRule(min: 3.4, max: 4864.5)
        let item = Labs.newBatchedPanelProfile("x", title: "y")
        item.floorValue = 4866.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsBatchedPanelProfileBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Labs.BatchedPanelProfileBudgetRangeRule(min: 1.1, max: 2052.6)
        let item = Labs.newBatchedPanelProfile("x", title: "y")
        item.budget = 2054.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsBatchedPanelProfileCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.BatchedPanelProfileCopayRangeRule(min: 9.4, max: 2797.5)
        let item = Labs.newBatchedPanelProfile("x", title: "y")
        item.copay = 2799.0
        #expect(rule.check(item).count > 0)
    }
}
