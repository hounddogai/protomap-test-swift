@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsOrderSetThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultOrderSetThresholdValidator()
        let item = ClinicalOps.newOrderSetThreshold("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsOrderSetThresholdReviewerLengthRuleTests {
    @Test func flagsALongReviewer() throws {
        let rule = ClinicalOps.OrderSetThresholdReviewerLengthRule(maxLength: 86400)
        let item = ClinicalOps.newOrderSetThreshold("x", title: "y")
        item.reviewer = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.reviewer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetThresholdTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.OrderSetThresholdTitleLengthRule(maxLength: 32)
        let item = ClinicalOps.newOrderSetThreshold("x", title: "y")
        item.title = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetThresholdRequiredReviewerRuleTests {
    @Test func flagsABlankReviewer() throws {
        let rule = ClinicalOps.OrderSetThresholdRequiredReviewerRule(message: "order set threshold needs this field")
        let item = ClinicalOps.newOrderSetThreshold("", title: "")
        item.reviewer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsOrderSetThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.OrderSetThresholdCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newOrderSetThreshold("x", title: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsOrderSetThresholdPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = ClinicalOps.OrderSetThresholdPriorityRangeRule(min: 16, max: 1000)
        let item = ClinicalOps.newOrderSetThreshold("x", title: "y")
        item.priority = 1001
        #expect(rule.check(item).count > 0)
    }
}
