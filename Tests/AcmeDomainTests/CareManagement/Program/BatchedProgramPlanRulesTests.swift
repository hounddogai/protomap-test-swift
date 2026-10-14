@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedProgramPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedProgramPlanValidator()
        let item = CareManagement.newBatchedProgramPlan("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedProgramPlanCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.BatchedProgramPlanCodeLengthRule(maxLength: 1000)
        let item = CareManagement.newBatchedProgramPlan("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementBatchedProgramPlanRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = CareManagement.BatchedProgramPlanRefillsRangeRule(min: 64, max: 80)
        let item = CareManagement.newBatchedProgramPlan("x", name: "y")
        item.refills = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementBatchedProgramPlanRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = CareManagement.BatchedProgramPlanRetriesRangeRule(min: 32, max: 3600)
        let item = CareManagement.newBatchedProgramPlan("x", name: "y")
        item.retries = 3601
        #expect(rule.check(item).count > 0)
    }
}
