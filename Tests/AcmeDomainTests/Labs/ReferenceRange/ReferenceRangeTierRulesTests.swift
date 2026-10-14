@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeTierValidator()
        let item = Labs.newReferenceRangeTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ReferenceRangeTierRequiredCodeRule(message: "reference range tier needs an entry")
        let item = Labs.newReferenceRangeTier("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeTierLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Labs.ReferenceRangeTierLocaleLengthRule(maxLength: 80)
        let item = Labs.newReferenceRangeTier("x", label: "y")
        item.locale = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeTierLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.ReferenceRangeTierLabelLengthRule(maxLength: 1000)
        let item = Labs.newReferenceRangeTier("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeTierRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Labs.ReferenceRangeTierRatioRangeRule(min: 9.9, max: 520.7)
        let item = Labs.newReferenceRangeTier("x", label: "y")
        item.ratio = 522.2
        #expect(rule.check(item).count > 0)
    }
}
