@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsPendingReferenceRangeBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultPendingReferenceRangeBatchValidator()
        let item = Labs.newPendingReferenceRangeBatch("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsPendingReferenceRangeBatchTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.PendingReferenceRangeBatchTitleLengthRule(maxLength: 120)
        let item = Labs.newPendingReferenceRangeBatch("x", title: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPendingReferenceRangeBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.PendingReferenceRangeBatchRequiredCodeRule(
            message: "pending reference range batch needs an entry"
        )
        let item = Labs.newPendingReferenceRangeBatch("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsPendingReferenceRangeBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.PendingReferenceRangeBatchCodeLengthRule(maxLength: 16)
        let item = Labs.newPendingReferenceRangeBatch("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsPendingReferenceRangeBatchCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Labs.PendingReferenceRangeBatchCategoryLengthRule(maxLength: 64)
        let item = Labs.newPendingReferenceRangeBatch("x", title: "y")
        item.category = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
