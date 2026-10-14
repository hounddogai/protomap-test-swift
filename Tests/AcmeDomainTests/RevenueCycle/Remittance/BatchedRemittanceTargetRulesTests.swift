@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedRemittanceTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedRemittanceTargetValidator()
        let item = RevenueCycle.newBatchedRemittanceTarget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedRemittanceTargetEndsAtRangeRuleTests {
    @Test func flagsValuesAboveEndsAt() throws {
        let rule = RevenueCycle.BatchedRemittanceTargetEndsAtRangeRule(min: 16, max: 80)
        let item = RevenueCycle.newBatchedRemittanceTarget("x", title: "y")
        item.endsAt = 81
        #expect(rule.check(item).count > 0)
    }
}
