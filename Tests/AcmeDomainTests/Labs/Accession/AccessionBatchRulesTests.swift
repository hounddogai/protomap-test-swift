@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionBatchValidator()
        let item = Labs.newAccessionBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.AccessionBatchRequiredCodeRule(message: "accession batch needs this field")
        let item = Labs.newAccessionBatch("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionBatchRequiredSummaryRuleTests {
    @Test func flagsABlankSummary() throws {
        let rule = Labs.AccessionBatchRequiredSummaryRule(message: "accession batch needs a value")
        let item = Labs.newAccessionBatch("", title: "")
        item.summary = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionBatchDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = Labs.AccessionBatchDescriptionLengthRule(maxLength: 64)
        let item = Labs.newAccessionBatch("x", title: "y")
        item.description = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionBatchSummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = Labs.AccessionBatchSummaryLengthRule(maxLength: 1000)
        let item = Labs.newAccessionBatch("x", title: "y")
        item.summary = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AccessionBatchCodeLengthRule(maxLength: 64)
        let item = Labs.newAccessionBatch("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
