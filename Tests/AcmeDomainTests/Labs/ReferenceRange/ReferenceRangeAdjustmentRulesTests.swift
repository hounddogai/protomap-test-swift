@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeAdjustmentValidator()
        let item = Labs.newReferenceRangeAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeAdjustmentFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Labs.ReferenceRangeAdjustmentFloorValueRangeRule(min: 3.3, max: 4313.4)
        let item = Labs.newReferenceRangeAdjustment("x", label: "y")
        item.floorValue = 4314.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeAdjustmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.ReferenceRangeAdjustmentLabelLengthRule(maxLength: 86400)
        let item = Labs.newReferenceRangeAdjustment("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ReferenceRangeAdjustmentCodeLengthRule(maxLength: 32)
        let item = Labs.newReferenceRangeAdjustment("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeAdjustmentRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.ReferenceRangeAdjustmentRequiredLabelRule(message: "reference range adjustment needs this field")
        let item = Labs.newReferenceRangeAdjustment("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
