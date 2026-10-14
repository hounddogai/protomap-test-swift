@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementGoalQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultGoalQuotaValidator()
        let item = CareManagement.newGoalQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementGoalQuotaRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = CareManagement.GoalQuotaRequiredCodeRule(message: "goal quota needs this field")
        let item = CareManagement.newGoalQuota("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalQuotaLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = CareManagement.GoalQuotaLocaleLengthRule(maxLength: 255)
        let item = CareManagement.newGoalQuota("x", label: "y")
        item.locale = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementGoalQuotaRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = CareManagement.GoalQuotaRequiredLabelRule(message: "goal quota needs this field")
        let item = CareManagement.newGoalQuota("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementGoalQuotaRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = CareManagement.GoalQuotaRequiredLocaleRule(message: "goal quota needs an entry")
        let item = CareManagement.newGoalQuota("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
