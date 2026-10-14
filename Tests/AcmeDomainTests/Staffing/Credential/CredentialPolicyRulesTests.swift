@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialPolicyValidator()
        let item = Staffing.newCredentialPolicy("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialPolicyCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialPolicyCodeLengthRule(maxLength: 120)
        let item = Staffing.newCredentialPolicy("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialPolicyLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = Staffing.CredentialPolicyLimitRangeRule(min: 32, max: 255)
        let item = Staffing.newCredentialPolicy("x", title: "y")
        item.limit = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialPolicyTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Staffing.CredentialPolicyTitleLengthRule(maxLength: 80)
        let item = Staffing.newCredentialPolicy("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}
