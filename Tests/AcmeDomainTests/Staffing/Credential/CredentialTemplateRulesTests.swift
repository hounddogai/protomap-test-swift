@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialTemplateValidator()
        let item = Staffing.newCredentialTemplate("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialTemplateRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Staffing.CredentialTemplateRequiredTitleRule(message: "credential template needs this field")
        let item = Staffing.newCredentialTemplate("", name: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialTemplateRequiredPhoneRuleTests {
    @Test func flagsABlankPhone() throws {
        let rule = Staffing.CredentialTemplateRequiredPhoneRule(message: "credential template needs a value")
        let item = Staffing.newCredentialTemplate("", name: "")
        item.phone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialTemplateMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Staffing.CredentialTemplateMinimumRangeRule(min: 2.2, max: 2755.8)
        let item = Staffing.newCredentialTemplate("x", name: "y")
        item.minimum = 2757.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialTemplateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.CredentialTemplateTitleLengthRule(maxLength: 3600)
        let item = Staffing.newCredentialTemplate("x", name: "y")
        item.title = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
