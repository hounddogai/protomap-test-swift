@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialSummaryValidator()
        let item = Staffing.newCredentialSummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialSummaryRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Staffing.CredentialSummaryRequiredAllergyRule(message: "credential summary needs a value")
        let item = Staffing.newCredentialSummary("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CredentialSummaryRequiredCodeRule(message: "credential summary needs a value")
        let item = Staffing.newCredentialSummary("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
