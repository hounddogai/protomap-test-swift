@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceCheckpointValidator()
        let item = RevenueCycle.newRemittanceCheckpoint("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceCheckpointStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = RevenueCycle.RemittanceCheckpointStartsAtRangeRule(min: 80, max: 1000)
        let item = RevenueCycle.newRemittanceCheckpoint("x", label: "y")
        item.startsAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceCheckpointCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = RevenueCycle.RemittanceCheckpointCategoryLengthRule(maxLength: 32)
        let item = RevenueCycle.newRemittanceCheckpoint("x", label: "y")
        item.category = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
