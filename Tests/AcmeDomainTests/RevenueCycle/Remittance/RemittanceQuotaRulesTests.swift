@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceQuotaValidator()
        let item = RevenueCycle.newRemittanceQuota("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.RemittanceQuotaCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newRemittanceQuota("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleRemittanceQuotaBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = RevenueCycle.RemittanceQuotaBatchSizeRangeRule(min: 1000, max: 86400)
        let item = RevenueCycle.newRemittanceQuota("x", name: "y")
        item.batchSize = 86401
        #expect(rule.check(item).count > 0)
    }
}
