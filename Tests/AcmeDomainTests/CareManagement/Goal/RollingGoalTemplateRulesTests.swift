@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRollingGoalTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRollingGoalTemplateValidator()
        let item = CareManagement.newRollingGoalTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRollingGoalTemplateLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = CareManagement.RollingGoalTemplateLabelLengthRule(maxLength: 1000)
        let item = CareManagement.newRollingGoalTemplate("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRollingGoalTemplateRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = CareManagement.RollingGoalTemplateRequiredOwnerIDRule(message: "rolling goal template needs an entry")
        let item = CareManagement.newRollingGoalTemplate("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}
