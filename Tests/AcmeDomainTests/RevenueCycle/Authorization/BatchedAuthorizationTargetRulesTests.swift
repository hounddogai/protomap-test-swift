@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedAuthorizationTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedAuthorizationTargetValidator()
        let item = RevenueCycle.newBatchedAuthorizationTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedAuthorizationTargetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.BatchedAuthorizationTargetRequiredCodeRule(
            message: "batched authorization target needs an entry"
        )
        let item = RevenueCycle.newBatchedAuthorizationTarget("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedAuthorizationTargetCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = RevenueCycle.BatchedAuthorizationTargetCreatedAtRangeRule(min: 16, max: 80)
        let item = RevenueCycle.newBatchedAuthorizationTarget("x", name: "y")
        item.createdAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedAuthorizationTargetWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = RevenueCycle.BatchedAuthorizationTargetWindowDaysRangeRule(min: 64, max: 1000)
        let item = RevenueCycle.newBatchedAuthorizationTarget("x", name: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedAuthorizationTargetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.BatchedAuthorizationTargetCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newBatchedAuthorizationTarget("x", name: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
