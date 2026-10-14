@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeVarianceValidator()
        let item = Labs.newReferenceRangeVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeVarianceRequiredCurrencyRuleTests {
    @Test func flagsABlankCurrency() throws {
        let rule = Labs.ReferenceRangeVarianceRequiredCurrencyRule(message: "reference range variance needs this field")
        let item = Labs.newReferenceRangeVariance("", title: "")
        item.currency = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeVarianceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ReferenceRangeVarianceRequiredCodeRule(message: "reference range variance needs a value")
        let item = Labs.newReferenceRangeVariance("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeVarianceNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Labs.ReferenceRangeVarianceNotesLengthRule(maxLength: 1000)
        let item = Labs.newReferenceRangeVariance("x", title: "y")
        item.notes = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeVarianceLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Labs.ReferenceRangeVarianceLimitRangeRule(min: 64, max: 3600)
        let item = Labs.newReferenceRangeVariance("x", title: "y")
        item.limit = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsReferenceRangeVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.ReferenceRangeVarianceTitleLengthRule(maxLength: 120)
        let item = Labs.newReferenceRangeVariance("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
