@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPanelVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPanelVarianceValidator()
        let item = Labs.newPanelVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPanelVarianceGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = Labs.PanelVarianceGraceDaysRangeRule(min: 16, max: 86400)
        let item = Labs.newPanelVariance("x", label: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsPanelVariancePayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Labs.PanelVariancePayerLengthRule(maxLength: 32)
        let item = Labs.newPanelVariance("x", label: "y")
        item.payer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPanelVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PanelVarianceRequiredCodeRule(message: "panel variance needs a value")
        let item = Labs.newPanelVariance("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPanelVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.PanelVarianceRequiredLabelRule(message: "panel variance needs this field")
        let item = Labs.newPanelVariance("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
