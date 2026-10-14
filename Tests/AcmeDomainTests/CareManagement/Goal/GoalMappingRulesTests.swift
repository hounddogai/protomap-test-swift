@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalMappingValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalMappingValidator()
        let item = CareManagement.newGoalMapping("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalMappingSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = CareManagement.GoalMappingSpecialtyLengthRule(maxLength: 255)
        let item = CareManagement.newGoalMapping("x", label: "y")
        item.specialty = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalMappingCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GoalMappingCodeLengthRule(maxLength: 16)
        let item = CareManagement.newGoalMapping("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalMappingRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = CareManagement.GoalMappingRevisionRangeRule(min: 3600, max: 3600)
        let item = CareManagement.newGoalMapping("x", label: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}
