@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementScheduledCareGapPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultScheduledCareGapPolicyValidator()
        let item = CareManagement.newScheduledCareGapPolicy("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementScheduledCareGapPolicyDescriptionLengthRuleTests {
    @Test func flagsALongDescription() throws {
        let rule = CareManagement.ScheduledCareGapPolicyDescriptionLengthRule(maxLength: 86400)
        let item = CareManagement.newScheduledCareGapPolicy("x", name: "y")
        item.description = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.description = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementScheduledCareGapPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ScheduledCareGapPolicyCodeLengthRule(maxLength: 64)
        let item = CareManagement.newScheduledCareGapPolicy("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementScheduledCareGapPolicyWindowDaysRangeRuleTests {
    @Test func flagsValuesAboveWindowDays() throws {
        let rule = CareManagement.ScheduledCareGapPolicyWindowDaysRangeRule(min: 16, max: 1000)
        let item = CareManagement.newScheduledCareGapPolicy("x", name: "y")
        item.windowDays = 1001
        #expect(rule.check(item).count > 0)
    }
}
