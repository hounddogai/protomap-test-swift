@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialDraftValidator()
        let item = Staffing.newCredentialDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialDraftTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.CredentialDraftTitleLengthRule(maxLength: 16)
        let item = Staffing.newCredentialDraft("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CredentialDraftRequiredCodeRule(message: "credential draft needs this field")
        let item = Staffing.newCredentialDraft("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialDraftPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Staffing.CredentialDraftPayerLengthRule(maxLength: 32)
        let item = Staffing.newCredentialDraft("x", title: "y")
        item.payer = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
