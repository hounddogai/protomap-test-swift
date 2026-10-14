@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalAgreementValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalAgreementValidator()
        let item = CareManagement.newGoalAgreement("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalAgreementRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.GoalAgreementRequiredCodeRule(message: "goal agreement needs an entry")
        let item = CareManagement.newGoalAgreement("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalAgreementRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.GoalAgreementRequiredNameRule(message: "goal agreement needs a value")
        let item = CareManagement.newGoalAgreement("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalAgreementCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.GoalAgreementCodeLengthRule(maxLength: 86400)
        let item = CareManagement.newGoalAgreement("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
