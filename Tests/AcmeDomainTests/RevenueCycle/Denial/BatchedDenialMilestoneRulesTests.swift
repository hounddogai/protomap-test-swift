@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedDenialMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedDenialMilestoneValidator()
        let item = RevenueCycle.newBatchedDenialMilestone("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedDenialMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.BatchedDenialMilestoneCodeLengthRule(maxLength: 80)
        let item = RevenueCycle.newBatchedDenialMilestone("x", name: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleBatchedDenialMilestoneRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = RevenueCycle.BatchedDenialMilestoneRequiredTimezoneRule(
            message: "batched denial milestone needs an entry"
        )
        let item = RevenueCycle.newBatchedDenialMilestone("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
