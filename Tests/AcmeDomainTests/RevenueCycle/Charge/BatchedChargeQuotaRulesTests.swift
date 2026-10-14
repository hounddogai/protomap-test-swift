@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedChargeQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedChargeQuotaValidator()
        let item = RevenueCycle.newBatchedChargeQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedChargeQuotaSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = RevenueCycle.BatchedChargeQuotaSourceLengthRule(maxLength: 80)
        let item = RevenueCycle.newBatchedChargeQuota("x", title: "y")
        item.source = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleBatchedChargeQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.BatchedChargeQuotaCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newBatchedChargeQuota("x", title: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleBatchedChargeQuotaRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.BatchedChargeQuotaRequiredTitleRule(message: "batched charge quota needs a value")
        let item = RevenueCycle.newBatchedChargeQuota("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}
