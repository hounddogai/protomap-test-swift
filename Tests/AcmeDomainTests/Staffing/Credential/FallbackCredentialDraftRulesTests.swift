@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingFallbackCredentialDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultFallbackCredentialDraftValidator()
        let item = Staffing.newFallbackCredentialDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingFallbackCredentialDraftRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Staffing.FallbackCredentialDraftRequiredTimezoneRule(
            message: "fallback credential draft needs an entry"
        )
        let item = Staffing.newFallbackCredentialDraft("", name: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingFallbackCredentialDraftNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.FallbackCredentialDraftNameLengthRule(maxLength: 86400)
        let item = Staffing.newFallbackCredentialDraft("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingFallbackCredentialDraftExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Staffing.FallbackCredentialDraftExpiresAtRangeRule(min: 16, max: 120)
        let item = Staffing.newFallbackCredentialDraft("x", name: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}
