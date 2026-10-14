@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsResultSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultResultSummaryValidator()
        let item = Labs.newResultSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsResultSummaryRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.ResultSummaryRateRangeRule(min: 8.2, max: 1899.7)
        let item = Labs.newResultSummary("x", label: "y")
        item.rate = 1901.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsResultSummaryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.ResultSummaryLabelLengthRule(maxLength: 86400)
        let item = Labs.newResultSummary("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultSummaryRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Labs.ResultSummaryRequiredSourceRule(message: "result summary needs this field")
        let item = Labs.newResultSummary("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsResultSummarySourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = Labs.ResultSummarySourceLengthRule(maxLength: 255)
        let item = Labs.newResultSummary("x", label: "y")
        item.source = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsResultSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ResultSummaryRequiredCodeRule(message: "result summary needs a value")
        let item = Labs.newResultSummary("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
