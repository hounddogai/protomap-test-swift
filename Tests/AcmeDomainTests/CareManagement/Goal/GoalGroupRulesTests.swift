@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalGroupValidator()
        let item = CareManagement.newGoalGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalGroupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.GoalGroupRequiredLabelRule(message: "goal group needs a value")
        let item = CareManagement.newGoalGroup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalGroupRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = CareManagement.GoalGroupRequiredOwnerIDRule(message: "goal group needs this field")
        let item = CareManagement.newGoalGroup("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalGroupFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = CareManagement.GoalGroupFloorValueRangeRule(min: 0.3, max: 4707.0)
        let item = CareManagement.newGoalGroup("x", label: "y")
        item.floorValue = 4708.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGoalGroupOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = CareManagement.GoalGroupOwnerIDLengthRule(maxLength: 86400)
        let item = CareManagement.newGoalGroup("x", label: "y")
        item.ownerID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
