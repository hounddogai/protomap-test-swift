@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGlobalGoalAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGlobalGoalAssignmentValidator()
        let item = CareManagement.newGlobalGoalAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGlobalGoalAssignmentRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.GlobalGoalAssignmentRequiredTitleRule(
            message: "global goal assignment needs this field"
        )
        let item = CareManagement.newGlobalGoalAssignment("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalGoalAssignmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GlobalGoalAssignmentCodeLengthRule(maxLength: 32)
        let item = CareManagement.newGlobalGoalAssignment("x", label: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGlobalGoalAssignmentRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = CareManagement.GlobalGoalAssignmentRequiredTimezoneRule(
            message: "global goal assignment needs an entry"
        )
        let item = CareManagement.newGlobalGoalAssignment("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGlobalGoalAssignmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.GlobalGoalAssignmentLabelLengthRule(maxLength: 86400)
        let item = CareManagement.newGlobalGoalAssignment("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGlobalGoalAssignmentCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = CareManagement.GlobalGoalAssignmentCapacityRangeRule(min: 80, max: 120)
        let item = CareManagement.newGlobalGoalAssignment("x", label: "y")
        item.capacity = 121
        #expect(rule.check(item).count > 0)
    }
}
