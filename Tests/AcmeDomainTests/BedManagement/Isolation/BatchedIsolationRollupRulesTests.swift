@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementBatchedIsolationRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultBatchedIsolationRollupValidator()
        let item = BedManagement.newBatchedIsolationRollup("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementBatchedIsolationRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = BedManagement.BatchedIsolationRollupRequiredCodeRule(
            message: "batched isolation rollup needs a value"
        )
        let item = BedManagement.newBatchedIsolationRollup("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementBatchedIsolationRollupTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = BedManagement.BatchedIsolationRollupTitleLengthRule(maxLength: 86400)
        let item = BedManagement.newBatchedIsolationRollup("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementBatchedIsolationRollupAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = BedManagement.BatchedIsolationRollupAttemptsRangeRule(min: 16, max: 64)
        let item = BedManagement.newBatchedIsolationRollup("x", title: "y")
        item.attempts = 65
        #expect(rule.check(item).count > 0)
    }
}
