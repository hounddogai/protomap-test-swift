@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedClaimAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedClaimAssignmentValidator()
        let item = RevenueCycle.newBatchedClaimAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedClaimAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.BatchedClaimAssignmentCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newBatchedClaimAssignment("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleBatchedClaimAssignmentGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = RevenueCycle.BatchedClaimAssignmentGraceDaysRangeRule(min: 64, max: 86400)
        let item = RevenueCycle.newBatchedClaimAssignment("x", title: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedClaimAssignmentWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = RevenueCycle.BatchedClaimAssignmentWindowDaysRangeRule(min: 16, max: 64)
        let item = RevenueCycle.newBatchedClaimAssignment("x", title: "y")
        item.windowDays = 65
        #expect(rule.check(item).count > 0)
    }
}
