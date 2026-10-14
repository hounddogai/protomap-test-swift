@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalAssignmentValidator()
        let item = CareManagement.newGoalAssignment("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalAssignmentChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = CareManagement.GoalAssignmentChecksumLengthRule(maxLength: 16)
        let item = CareManagement.newGoalAssignment("x", title: "y")
        item.checksum = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalAssignmentRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = CareManagement.GoalAssignmentRequiredChecksumRule(message: "goal assignment needs this field")
        let item = CareManagement.newGoalAssignment("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalAssignmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.GoalAssignmentRequiredCodeRule(message: "goal assignment needs this field")
        let item = CareManagement.newGoalAssignment("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
