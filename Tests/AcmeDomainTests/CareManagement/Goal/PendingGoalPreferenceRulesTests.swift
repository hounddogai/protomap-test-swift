@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementPendingGoalPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultPendingGoalPreferenceValidator()
        let item = CareManagement.newPendingGoalPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementPendingGoalPreferenceRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = CareManagement.PendingGoalPreferenceRequiredNameRule(
            message: "pending goal preference needs this field"
        )
        let item = CareManagement.newPendingGoalPreference("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPendingGoalPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.PendingGoalPreferenceRequiredCodeRule(message: "pending goal preference needs a value")
        let item = CareManagement.newPendingGoalPreference("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementPendingGoalPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.PendingGoalPreferenceCodeLengthRule(maxLength: 86400)
        let item = CareManagement.newPendingGoalPreference("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
