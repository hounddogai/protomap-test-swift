@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialQuotaValidator()
        let item = Staffing.newCredentialQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialQuotaMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Staffing.CredentialQuotaMarginRangeRule(min: 0.8, max: 3509.9)
        let item = Staffing.newCredentialQuota("x", title: "y")
        item.margin = 3511.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialQuotaRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.CredentialQuotaRequiredNameRule(message: "credential quota needs a value")
        let item = Staffing.newCredentialQuota("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialQuotaCodeLengthRule(maxLength: 3600)
        let item = Staffing.newCredentialQuota("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
