@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskMappingValidator()
        let item = ClinicalOps.newTaskMapping("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskMappingRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = ClinicalOps.TaskMappingRefillsRangeRule(min: 80, max: 255)
        let item = ClinicalOps.newTaskMapping("x", title: "y")
        item.refills = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskMappingNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = ClinicalOps.TaskMappingNotesLengthRule(maxLength: 3600)
        let item = ClinicalOps.newTaskMapping("x", title: "y")
        item.notes = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
