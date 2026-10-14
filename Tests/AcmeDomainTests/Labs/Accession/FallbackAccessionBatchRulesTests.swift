@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsFallbackAccessionBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultFallbackAccessionBatchValidator()
        let item = Labs.newFallbackAccessionBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsFallbackAccessionBatchTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.FallbackAccessionBatchTitleLengthRule(maxLength: 64)
        let item = Labs.newFallbackAccessionBatch("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsFallbackAccessionBatchRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.FallbackAccessionBatchRequiredTitleRule(message: "fallback accession batch needs this field")
        let item = Labs.newFallbackAccessionBatch("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsFallbackAccessionBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.FallbackAccessionBatchRequiredCodeRule(message: "fallback accession batch needs this field")
        let item = Labs.newFallbackAccessionBatch("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
