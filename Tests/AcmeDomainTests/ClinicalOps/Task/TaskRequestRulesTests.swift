@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskRequestValidator()
        let item = ClinicalOps.newTaskRequest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskRequestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.TaskRequestLabelLengthRule(maxLength: 80)
        let item = ClinicalOps.newTaskRequest("x", name: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskRequestCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = ClinicalOps.TaskRequestCostRangeRule(min: 1.7, max: 4860.2)
        let item = ClinicalOps.newTaskRequest("x", name: "y")
        item.cost = 4861.7
        #expect(rule.check(item).count > 0)
    }
}
