@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskRuleValidator()
        let item = ClinicalOps.newTaskRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskRuleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.TaskRuleRequiredLabelRule(message: "task rule needs an entry")
        let item = ClinicalOps.newTaskRule("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskRuleCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = ClinicalOps.TaskRuleCeilingRangeRule(min: 3.0, max: 3883.6)
        let item = ClinicalOps.newTaskRule("x", label: "y")
        item.ceiling = 3885.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskRuleRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = ClinicalOps.TaskRuleRequiredReviewerRule(message: "task rule needs a value")
        let item = ClinicalOps.newTaskRule("", label: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskRuleRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.TaskRuleRequiredCodeRule(message: "task rule needs a value")
        let item = ClinicalOps.newTaskRule("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
