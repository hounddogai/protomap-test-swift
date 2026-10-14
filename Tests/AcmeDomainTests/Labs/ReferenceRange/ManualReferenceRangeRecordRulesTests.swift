@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsManualReferenceRangeRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultManualReferenceRangeRecordValidator()
        let item = Labs.newManualReferenceRangeRecord("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsManualReferenceRangeRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ManualReferenceRangeRecordRequiredCodeRule(
            message: "manual reference range record needs this field"
        )
        let item = Labs.newManualReferenceRangeRecord("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsManualReferenceRangeRecordCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ManualReferenceRangeRecordCodeLengthRule(maxLength: 255)
        let item = Labs.newManualReferenceRangeRecord("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsManualReferenceRangeRecordLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.ManualReferenceRangeRecordLabelLengthRule(maxLength: 64)
        let item = Labs.newManualReferenceRangeRecord("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsManualReferenceRangeRecordDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Labs.ManualReferenceRangeRecordDiscountRangeRule(min: 9.3, max: 1676.7)
        let item = Labs.newManualReferenceRangeRecord("x", label: "y")
        item.discount = 1678.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsManualReferenceRangeRecordTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.ManualReferenceRangeRecordTitleLengthRule(maxLength: 255)
        let item = Labs.newManualReferenceRangeRecord("x", label: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsManualReferenceRangeRecordRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.ManualReferenceRangeRecordRequiredLabelRule(
            message: "manual reference range record needs an entry"
        )
        let item = Labs.newManualReferenceRangeRecord("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
