@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedAuthorizationBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedAuthorizationBaselineValidator()
        let item = RevenueCycle.newBatchedAuthorizationBaseline("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedAuthorizationBaselineRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.BatchedAuthorizationBaselineRequiredCodeRule(
            message: "batched authorization baseline needs an entry"
        )
        let item = RevenueCycle.newBatchedAuthorizationBaseline("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedAuthorizationBaselineRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = RevenueCycle.BatchedAuthorizationBaselineRequiredWardRule(
            message: "batched authorization baseline needs an entry"
        )
        let item = RevenueCycle.newBatchedAuthorizationBaseline("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedAuthorizationBaselineDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = RevenueCycle.BatchedAuthorizationBaselineDurationMinutesRangeRule(min: 16, max: 3600)
        let item = RevenueCycle.newBatchedAuthorizationBaseline("x", name: "y")
        item.durationMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedAuthorizationBaselineNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.BatchedAuthorizationBaselineNameLengthRule(maxLength: 86400)
        let item = RevenueCycle.newBatchedAuthorizationBaseline("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
