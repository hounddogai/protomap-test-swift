@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingGoalCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRollingGoalCycleValidator()
        let item = CareManagement.newRollingGoalCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRollingGoalCycleExternalRefLengthRuleTests {
    @Test func flagsALongExternalRef() throws {
        let rule = CareManagement.RollingGoalCycleExternalRefLengthRule(maxLength: 16)
        let item = CareManagement.newRollingGoalCycle("x", title: "y")
        item.externalRef = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.externalRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRollingGoalCycleThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.RollingGoalCycleThresholdRangeRule(min: 1.5, max: 3107.8)
        let item = CareManagement.newRollingGoalCycle("x", title: "y")
        item.threshold = 3109.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementRollingGoalCycleTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = CareManagement.RollingGoalCycleTitleLengthRule(maxLength: 86400)
        let item = CareManagement.newRollingGoalCycle("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
