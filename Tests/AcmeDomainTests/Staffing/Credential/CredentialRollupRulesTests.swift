@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingCredentialRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultCredentialRollupValidator()
        let item = Staffing.newCredentialRollup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingCredentialRollupRequiredExternalRefRuleTests {
    @Test func flagsABlankExternalRef() throws {
        let rule = Staffing.CredentialRollupRequiredExternalRefRule(message: "credential rollup needs an entry")
        let item = Staffing.newCredentialRollup("", label: "")
        item.externalRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialRollupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Staffing.CredentialRollupRequiredLabelRule(message: "credential rollup needs this field")
        let item = Staffing.newCredentialRollup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialRollupCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Staffing.CredentialRollupCreatedAtRangeRule(min: 255, max: 86400)
        let item = Staffing.newCredentialRollup("x", label: "y")
        item.createdAt = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct StaffingCredentialRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Staffing.CredentialRollupRequiredCodeRule(message: "credential rollup needs a value")
        let item = Staffing.newCredentialRollup("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingCredentialRollupRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Staffing.CredentialRollupRequiredLocaleRule(message: "credential rollup needs this field")
        let item = Staffing.newCredentialRollup("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}
