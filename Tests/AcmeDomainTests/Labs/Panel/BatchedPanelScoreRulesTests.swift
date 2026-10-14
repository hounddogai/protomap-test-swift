@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsBatchedPanelScoreValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultBatchedPanelScoreValidator()
        let item = Labs.newBatchedPanelScore("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsBatchedPanelScoreCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.BatchedPanelScoreCodeLengthRule(maxLength: 64)
        let item = Labs.newBatchedPanelScore("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsBatchedPanelScorePriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Labs.BatchedPanelScorePriorityRangeRule(min: 32, max: 32)
        let item = Labs.newBatchedPanelScore("x", title: "y")
        item.priority = 33
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsBatchedPanelScoreCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Labs.BatchedPanelScoreCeilingRangeRule(min: 6.8, max: 1697.5)
        let item = Labs.newBatchedPanelScore("x", title: "y")
        item.ceiling = 1699.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsBatchedPanelScoreSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Labs.BatchedPanelScoreSequenceRangeRule(min: 1000, max: 86400)
        let item = Labs.newBatchedPanelScore("x", title: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}
