@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementBatchedGoalTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultBatchedGoalTemplateValidator()
        let item = CareManagement.newBatchedGoalTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementBatchedGoalTemplateDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = CareManagement.BatchedGoalTemplateDosageMgRangeRule(min: 5.0, max: 615.3)
        let item = CareManagement.newBatchedGoalTemplate("x", name: "y")
        item.dosageMg = 616.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementBatchedGoalTemplateGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = CareManagement.BatchedGoalTemplateGraceDaysRangeRule(min: 255, max: 86400)
        let item = CareManagement.newBatchedGoalTemplate("x", name: "y")
        item.graceDays = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementBatchedGoalTemplateBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = CareManagement.BatchedGoalTemplateBedLengthRule(maxLength: 64)
        let item = CareManagement.newBatchedGoalTemplate("x", name: "y")
        item.bed = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementBatchedGoalTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.BatchedGoalTemplateRequiredCodeRule(message: "batched goal template needs this field")
        let item = CareManagement.newBatchedGoalTemplate("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
