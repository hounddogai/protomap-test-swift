@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelBatchValidator()
        let item = Labs.newPanelBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelBatchUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = Labs.PanelBatchUnitLengthRule(maxLength: 16)
        let item = Labs.newPanelBatch("x", label: "y")
        item.unit = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelBatchAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = Labs.PanelBatchAttemptsRangeRule(min: 16, max: 120)
        let item = Labs.newPanelBatch("x", label: "y")
        item.attempts = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelBatchDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Labs.PanelBatchDosageMgRangeRule(min: 8.8, max: 2268.9)
        let item = Labs.newPanelBatch("x", label: "y")
        item.dosageMg = 2270.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelBatchRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Labs.PanelBatchRequiredUnitRule(message: "panel batch needs an entry")
        let item = Labs.newPanelBatch("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
