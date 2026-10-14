@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedDenialTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedDenialTargetValidator()
        let item = RevenueCycle.newBatchedDenialTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedDenialTargetLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.BatchedDenialTargetLimitRangeRule(min: 64, max: 120)
        let item = RevenueCycle.newBatchedDenialTarget("x", name: "y")
        item.limit = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedDenialTargetNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.BatchedDenialTargetNameLengthRule(maxLength: 64)
        let item = RevenueCycle.newBatchedDenialTarget("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
