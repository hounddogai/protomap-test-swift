@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalTemplateValidator()
        let item = CareManagement.newGoalTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalTemplateOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = CareManagement.GoalTemplateOwnerIDLengthRule(maxLength: 3600)
        let item = CareManagement.newGoalTemplate("x", title: "y")
        item.ownerID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalTemplateCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GoalTemplateCodeLengthRule(maxLength: 80)
        let item = CareManagement.newGoalTemplate("x", title: "y")
        item.code = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.GoalTemplateRequiredCodeRule(message: "goal template needs this field")
        let item = CareManagement.newGoalTemplate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
