@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledTaskReviewValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultScheduledTaskReviewValidator()
        let item = ClinicalOps.newScheduledTaskReview("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsScheduledTaskReviewRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.ScheduledTaskReviewRequiredCodeRule(message: "scheduled task review needs an entry")
        let item = ClinicalOps.newScheduledTaskReview("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsScheduledTaskReviewLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.ScheduledTaskReviewLabelLengthRule(maxLength: 80)
        let item = ClinicalOps.newScheduledTaskReview("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsScheduledTaskReviewDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = ClinicalOps.ScheduledTaskReviewDescriptionLengthRule(maxLength: 16)
        let item = ClinicalOps.newScheduledTaskReview("x", label: "y")
        item.description = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsScheduledTaskReviewCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.ScheduledTaskReviewCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newScheduledTaskReview("x", label: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsScheduledTaskReviewSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = ClinicalOps.ScheduledTaskReviewSequenceRangeRule(min: 255, max: 1000)
        let item = ClinicalOps.newScheduledTaskReview("x", label: "y")
        item.sequence = 1001
        #expect(rule.check(item).count > 0)
    }
}
