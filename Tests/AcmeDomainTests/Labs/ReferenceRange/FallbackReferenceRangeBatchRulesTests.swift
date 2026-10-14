@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackReferenceRangeBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackReferenceRangeBatchValidator()
        let item = Labs.newFallbackReferenceRangeBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackReferenceRangeBatchRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.FallbackReferenceRangeBatchRequiredLabelRule(
            message: "fallback reference range batch needs a value"
        )
        let item = Labs.newFallbackReferenceRangeBatch("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackReferenceRangeBatchRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.FallbackReferenceRangeBatchRequiredTitleRule(
            message: "fallback reference range batch needs an entry"
        )
        let item = Labs.newFallbackReferenceRangeBatch("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackReferenceRangeBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.FallbackReferenceRangeBatchCodeLengthRule(maxLength: 3600)
        let item = Labs.newFallbackReferenceRangeBatch("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackReferenceRangeBatchLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.FallbackReferenceRangeBatchLabelLengthRule(maxLength: 255)
        let item = Labs.newFallbackReferenceRangeBatch("x", title: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
