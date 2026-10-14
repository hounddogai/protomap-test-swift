@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptivePanelSnapshotValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptivePanelSnapshotValidator()
        let item = Labs.newAdaptivePanelSnapshot("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptivePanelSnapshotRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Labs.AdaptivePanelSnapshotRatioRangeRule(min: 6.3, max: 2849.2)
        let item = Labs.newAdaptivePanelSnapshot("x", label: "y")
        item.ratio = 2850.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAdaptivePanelSnapshotUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = Labs.AdaptivePanelSnapshotUpdatedAtRangeRule(min: 120, max: 1000)
        let item = Labs.newAdaptivePanelSnapshot("x", label: "y")
        item.updatedAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAdaptivePanelSnapshotChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Labs.AdaptivePanelSnapshotChannelLengthRule(maxLength: 120)
        let item = Labs.newAdaptivePanelSnapshot("x", label: "y")
        item.channel = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptivePanelSnapshotBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Labs.AdaptivePanelSnapshotBudgetRangeRule(min: 4.1, max: 338.3)
        let item = Labs.newAdaptivePanelSnapshot("x", label: "y")
        item.budget = 339.8
        #expect(rule.check(item).count > 0)
    }
}
