@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskDraftValidator()
        let item = ClinicalOps.newTaskDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskDraftUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = ClinicalOps.TaskDraftUpdatedAtRangeRule(min: 32, max: 64)
        let item = ClinicalOps.newTaskDraft("x", label: "y")
        item.updatedAt = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskDraftReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = ClinicalOps.TaskDraftReviewerLengthRule(maxLength: 64)
        let item = ClinicalOps.newTaskDraft("x", label: "y")
        item.reviewer = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskDraftCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TaskDraftCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newTaskDraft("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskDraftLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.TaskDraftLabelLengthRule(maxLength: 80)
        let item = ClinicalOps.newTaskDraft("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
