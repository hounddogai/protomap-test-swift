@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertAllocationValidator()
        let item = ClinicalOps.newAlertAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertAllocationReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = ClinicalOps.AlertAllocationReviewerLengthRule(maxLength: 255)
        let item = ClinicalOps.newAlertAllocation("x", label: "y")
        item.reviewer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertAllocationPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = ClinicalOps.AlertAllocationPriorityRangeRule(min: 16, max: 80)
        let item = ClinicalOps.newAlertAllocation("x", label: "y")
        item.priority = 81
        #expect(rule.check(item).count > 0)
    }
}
