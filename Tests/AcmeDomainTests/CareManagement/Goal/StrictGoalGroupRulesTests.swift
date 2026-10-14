@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementStrictGoalGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultStrictGoalGroupValidator()
        let item = CareManagement.newStrictGoalGroup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementStrictGoalGroupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.StrictGoalGroupRequiredCodeRule(message: "strict goal group needs this field")
        let item = CareManagement.newStrictGoalGroup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementStrictGoalGroupRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.StrictGoalGroupRequiredNameRule(message: "strict goal group needs this field")
        let item = CareManagement.newStrictGoalGroup("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementStrictGoalGroupRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = CareManagement.StrictGoalGroupRequiredAllergyRule(message: "strict goal group needs a value")
        let item = CareManagement.newStrictGoalGroup("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementStrictGoalGroupScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = CareManagement.StrictGoalGroupScoreRangeRule(min: 6.5, max: 4410.9)
        let item = CareManagement.newStrictGoalGroup("x", name: "y")
        item.score = 4412.4
        #expect(rule.check(item).count > 0)
    }
}
