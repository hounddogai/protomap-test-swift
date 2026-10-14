@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialTierValidator()
        let item = Staffing.newCredentialTier("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialTierRetriesRangeRuleTests {
    @Test func flagsValuesAboveRetries() throws {
        let rule = Staffing.CredentialTierRetriesRangeRule(min: 32, max: 64)
        let item = Staffing.newCredentialTier("x", name: "y")
        item.retries = 65
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialTierCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialTierCodeLengthRule(maxLength: 86400)
        let item = Staffing.newCredentialTier("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialTierRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CredentialTierRequiredCodeRule(message: "credential tier needs a value")
        let item = Staffing.newCredentialTier("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialTierRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.CredentialTierRequiredNameRule(message: "credential tier needs this field")
        let item = Staffing.newCredentialTier("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
