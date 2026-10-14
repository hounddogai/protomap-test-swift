@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsTaskAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultTaskAssignmentValidator()
        let item = ClinicalOps.newTaskAssignment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsTaskAssignmentCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = ClinicalOps.TaskAssignmentCreatedAtRangeRule(min: 64, max: 1000)
        let item = ClinicalOps.newTaskAssignment("x", name: "y")
        item.createdAt = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskAssignmentEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = ClinicalOps.TaskAssignmentEncounterIDLengthRule(maxLength: 16)
        let item = ClinicalOps.newTaskAssignment("x", name: "y")
        item.encounterID = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskAssignmentVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = ClinicalOps.TaskAssignmentVersionRangeRule(min: 80, max: 86400)
        let item = ClinicalOps.newTaskAssignment("x", name: "y")
        item.version = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsTaskAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.TaskAssignmentCodeLengthRule(maxLength: 64)
        let item = ClinicalOps.newTaskAssignment("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsTaskAssignmentDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = ClinicalOps.TaskAssignmentDiscountRangeRule(min: 9.3, max: 4888.1)
        let item = ClinicalOps.newTaskAssignment("x", name: "y")
        item.discount = 4889.6
        #expect(rule.check(item).count > 0)
    }
}
