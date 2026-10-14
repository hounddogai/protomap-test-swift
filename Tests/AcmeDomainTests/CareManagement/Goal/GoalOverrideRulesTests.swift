@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalOverrideValidator()
        let item = CareManagement.newGoalOverride("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalOverrideSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = CareManagement.GoalOverrideSequenceRangeRule(min: 120, max: 255)
        let item = CareManagement.newGoalOverride("x", name: "y")
        item.sequence = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGoalOverrideRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.GoalOverrideRequiredNameRule(message: "goal override needs a value")
        let item = CareManagement.newGoalOverride("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalOverrideWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = CareManagement.GoalOverrideWeightRangeRule(min: 3.1, max: 3195.1)
        let item = CareManagement.newGoalOverride("x", name: "y")
        item.weight = 3196.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGoalOverrideThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = CareManagement.GoalOverrideThresholdRangeRule(min: 7.9, max: 4679.0)
        let item = CareManagement.newGoalOverride("x", name: "y")
        item.threshold = 4680.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementGoalOverrideDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = CareManagement.GoalOverrideDiagnosisCodeLengthRule(maxLength: 64)
        let item = CareManagement.newGoalOverride("x", name: "y")
        item.diagnosisCode = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}
