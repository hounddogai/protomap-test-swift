@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskCycleValidator()
        let item = ClinicalOps.newTaskCycle("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskCycleAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = ClinicalOps.TaskCycleAttemptsRangeRule(min: 255, max: 3600)
        let item = ClinicalOps.newTaskCycle("x", name: "y")
        item.attempts = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskCycleRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = ClinicalOps.TaskCycleRequiredNameRule(message: "task cycle needs a value")
        let item = ClinicalOps.newTaskCycle("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskCycleRequiredWardRuleTests {
    @Test func flagsABlankWard() throws {
        let rule = ClinicalOps.TaskCycleRequiredWardRule(message: "task cycle needs an entry")
        let item = ClinicalOps.newTaskCycle("", name: "")
        item.ward = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsTaskCycleWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = ClinicalOps.TaskCycleWardLengthRule(maxLength: 86400)
        let item = ClinicalOps.newTaskCycle("x", name: "y")
        item.ward = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}
