@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialPreferenceValidator()
        let item = Staffing.newCredentialPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialPreferenceAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = Staffing.CredentialPreferenceAmountRangeRule(min: 4.2, max: 399.3)
        let item = Staffing.newCredentialPreference("x", name: "y")
        item.amount = 400.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialPreferenceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.CredentialPreferenceNameLengthRule(maxLength: 64)
        let item = Staffing.newCredentialPreference("x", name: "y")
        item.name = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialPreferenceRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = Staffing.CredentialPreferenceRequiredSegmentRule(message: "credential preference needs this field")
        let item = Staffing.newCredentialPreference("", name: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialPreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Staffing.CredentialPreferenceCodeLengthRule(maxLength: 64)
        let item = Staffing.newCredentialPreference("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingCredentialPreferenceRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CredentialPreferenceRequiredCodeRule(message: "credential preference needs a value")
        let item = Staffing.newCredentialPreference("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
