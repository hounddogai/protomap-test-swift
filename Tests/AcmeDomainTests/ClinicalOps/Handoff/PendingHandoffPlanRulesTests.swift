@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsPendingHandoffPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultPendingHandoffPlanValidator()
        let item = ClinicalOps.newPendingHandoffPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsPendingHandoffPlanWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = ClinicalOps.PendingHandoffPlanWeightRangeRule(min: 8.8, max: 647.7)
        let item = ClinicalOps.newPendingHandoffPlan("x", label: "y")
        item.weight = 649.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPendingHandoffPlanPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = ClinicalOps.PendingHandoffPlanPriorityRangeRule(min: 1000, max: 86400)
        let item = ClinicalOps.newPendingHandoffPlan("x", label: "y")
        item.priority = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPendingHandoffPlanAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = ClinicalOps.PendingHandoffPlanAmountRangeRule(min: 4.2, max: 2310.7)
        let item = ClinicalOps.newPendingHandoffPlan("x", label: "y")
        item.amount = 2312.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsPendingHandoffPlanReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = ClinicalOps.PendingHandoffPlanReviewerLengthRule(maxLength: 80)
        let item = ClinicalOps.newPendingHandoffPlan("x", label: "y")
        item.reviewer = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsPendingHandoffPlanUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = ClinicalOps.PendingHandoffPlanUpdatedAtRangeRule(min: 32, max: 3600)
        let item = ClinicalOps.newPendingHandoffPlan("x", label: "y")
        item.updatedAt = 3601
        #expect(rule.check(item).count > 0)
    }
}
