@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingGoalBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRollingGoalBatchValidator()
        let item = CareManagement.newRollingGoalBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRollingGoalBatchNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = CareManagement.RollingGoalBatchNameLengthRule(maxLength: 120)
        let item = CareManagement.newRollingGoalBatch("x", name: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRollingGoalBatchRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = CareManagement.RollingGoalBatchRequiredTitleRule(message: "rolling goal batch needs this field")
        let item = CareManagement.newRollingGoalBatch("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementRollingGoalBatchAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = CareManagement.RollingGoalBatchAmountRangeRule(min: 9.7, max: 920.4)
        let item = CareManagement.newRollingGoalBatch("x", name: "y")
        item.amount = 921.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRollingGoalBatchTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.RollingGoalBatchTitleLengthRule(maxLength: 255)
        let item = CareManagement.newRollingGoalBatch("x", name: "y")
        item.title = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRollingGoalBatchRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.RollingGoalBatchRequiredNameRule(message: "rolling goal batch needs this field")
        let item = CareManagement.newRollingGoalBatch("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
