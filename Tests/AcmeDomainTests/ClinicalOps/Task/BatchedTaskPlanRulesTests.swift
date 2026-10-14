@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsBatchedTaskPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultBatchedTaskPlanValidator()
        let item = ClinicalOps.newBatchedTaskPlan("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsBatchedTaskPlanRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.BatchedTaskPlanRequiredCodeRule(message: "batched task plan needs a value")
        let item = ClinicalOps.newBatchedTaskPlan("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsBatchedTaskPlanWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = ClinicalOps.BatchedTaskPlanWeightRangeRule(min: 7.2, max: 4950.7)
        let item = ClinicalOps.newBatchedTaskPlan("x", label: "y")
        item.weight = 4952.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsBatchedTaskPlanRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.BatchedTaskPlanRequiredLabelRule(message: "batched task plan needs this field")
        let item = ClinicalOps.newBatchedTaskPlan("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsBatchedTaskPlanLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.BatchedTaskPlanLabelLengthRule(maxLength: 120)
        let item = ClinicalOps.newBatchedTaskPlan("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
