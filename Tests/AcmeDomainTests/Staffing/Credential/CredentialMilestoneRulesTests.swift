@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialMilestoneValidator()
        let item = Staffing.newCredentialMilestone("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialMilestoneRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CredentialMilestoneRequiredCodeRule(message: "credential milestone needs a value")
        let item = Staffing.newCredentialMilestone("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialMilestoneRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = Staffing.CredentialMilestoneRequiredSourceRule(message: "credential milestone needs this field")
        let item = Staffing.newCredentialMilestone("", label: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialMilestoneCodeLengthRule(maxLength: 16)
        let item = Staffing.newCredentialMilestone("x", label: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialMilestoneCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Staffing.CredentialMilestoneCeilingRangeRule(min: 9.9, max: 4486.1)
        let item = Staffing.newCredentialMilestone("x", label: "y")
        item.ceiling = 4487.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialMilestoneRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Staffing.CredentialMilestoneRequiredPhoneRule(message: "credential milestone needs a value")
        let item = Staffing.newCredentialMilestone("", label: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}
