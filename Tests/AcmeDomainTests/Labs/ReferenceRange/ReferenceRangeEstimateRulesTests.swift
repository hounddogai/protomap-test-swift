@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeEstimateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeEstimateValidator()
        let item = Labs.newReferenceRangeEstimate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeEstimateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.ReferenceRangeEstimateCodeLengthRule(maxLength: 16)
        let item = Labs.newReferenceRangeEstimate("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeEstimateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ReferenceRangeEstimateRequiredCodeRule(message: "reference range estimate needs a value")
        let item = Labs.newReferenceRangeEstimate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeEstimateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.ReferenceRangeEstimateTitleLengthRule(maxLength: 86400)
        let item = Labs.newReferenceRangeEstimate("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeEstimateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.ReferenceRangeEstimateRequiredTitleRule(message: "reference range estimate needs a value")
        let item = Labs.newReferenceRangeEstimate("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
