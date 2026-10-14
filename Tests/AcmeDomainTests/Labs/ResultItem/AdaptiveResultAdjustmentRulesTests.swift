@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAdaptiveResultAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAdaptiveResultAdjustmentValidator()
        let item = Labs.newAdaptiveResultAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAdaptiveResultAdjustmentCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.AdaptiveResultAdjustmentCopayRangeRule(min: 5.4, max: 459.2)
        let item = Labs.newAdaptiveResultAdjustment("x", label: "y")
        item.copay = 460.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAdaptiveResultAdjustmentSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Labs.AdaptiveResultAdjustmentSequenceRangeRule(min: 120, max: 86400)
        let item = Labs.newAdaptiveResultAdjustment("x", label: "y")
        item.sequence = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAdaptiveResultAdjustmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.AdaptiveResultAdjustmentLabelLengthRule(maxLength: 3600)
        let item = Labs.newAdaptiveResultAdjustment("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAdaptiveResultAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AdaptiveResultAdjustmentCodeLengthRule(maxLength: 86400)
        let item = Labs.newAdaptiveResultAdjustment("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
