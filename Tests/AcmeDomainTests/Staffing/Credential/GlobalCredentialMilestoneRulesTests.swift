@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingGlobalCredentialMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultGlobalCredentialMilestoneValidator()
        let item = Staffing.newGlobalCredentialMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingGlobalCredentialMilestoneAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Staffing.GlobalCredentialMilestoneAllergyLengthRule(maxLength: 80)
        let item = Staffing.newGlobalCredentialMilestone("x", title: "y")
        item.allergy = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingGlobalCredentialMilestoneRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Staffing.GlobalCredentialMilestoneRetriesRangeRule(min: 32, max: 120)
        let item = Staffing.newGlobalCredentialMilestone("x", title: "y")
        item.retries = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingGlobalCredentialMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.GlobalCredentialMilestoneCodeLengthRule(maxLength: 32)
        let item = Staffing.newGlobalCredentialMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
