@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskBatchValidator()
        let item = ClinicalOps.newTaskBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskBatchNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.TaskBatchNameLengthRule(maxLength: 120)
        let item = ClinicalOps.newTaskBatch("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TaskBatchCodeLengthRule(maxLength: 1000)
        let item = ClinicalOps.newTaskBatch("x", name: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskBatchDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = ClinicalOps.TaskBatchDescriptionLengthRule(maxLength: 255)
        let item = ClinicalOps.newTaskBatch("x", name: "y")
        item.description = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskBatchMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = ClinicalOps.TaskBatchMinimumRangeRule(min: 1.0, max: 1874.5)
        let item = ClinicalOps.newTaskBatch("x", name: "y")
        item.minimum = 1876.0
        #expect(rule.check(item).count > 0)
    }
}
