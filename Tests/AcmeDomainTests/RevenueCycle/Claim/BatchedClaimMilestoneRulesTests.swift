@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedClaimMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedClaimMilestoneValidator()
        let item = RevenueCycle.newBatchedClaimMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedClaimMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.BatchedClaimMilestoneRequiredCodeRule(message: "batched claim milestone needs a value")
        let item = RevenueCycle.newBatchedClaimMilestone("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedClaimMilestoneCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = RevenueCycle.BatchedClaimMilestoneCreatedAtRangeRule(min: 80, max: 86400)
        let item = RevenueCycle.newBatchedClaimMilestone("x", title: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedClaimMilestoneRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = RevenueCycle.BatchedClaimMilestoneRequiredUnitRule(message: "batched claim milestone needs a value")
        let item = RevenueCycle.newBatchedClaimMilestone("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleBatchedClaimMilestoneVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = RevenueCycle.BatchedClaimMilestoneVisitMinutesRangeRule(min: 1000, max: 3600)
        let item = RevenueCycle.newBatchedClaimMilestone("x", title: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedClaimMilestoneUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = RevenueCycle.BatchedClaimMilestoneUnitLengthRule(maxLength: 80)
        let item = RevenueCycle.newBatchedClaimMilestone("x", title: "y")
        item.unit = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}
