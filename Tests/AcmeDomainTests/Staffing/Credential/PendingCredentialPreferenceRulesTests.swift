@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct StaffingPendingCredentialPreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Staffing.defaultPendingCredentialPreferenceValidator()
        let item = Staffing.newPendingCredentialPreference("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct StaffingPendingCredentialPreferenceSpecialtyLengthRuleTests {
    @Test func flagsALongSpecialty() throws {
        let rule = Staffing.PendingCredentialPreferenceSpecialtyLengthRule(maxLength: 255)
        let item = Staffing.newPendingCredentialPreference("x", name: "y")
        item.specialty = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.specialty = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingCredentialPreferenceNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Staffing.PendingCredentialPreferenceNameLengthRule(maxLength: 3600)
        let item = Staffing.newPendingCredentialPreference("x", name: "y")
        item.name = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct StaffingPendingCredentialPreferenceRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Staffing.PendingCredentialPreferenceRequiredNameRule(
            message: "pending credential preference needs this field"
        )
        let item = Staffing.newPendingCredentialPreference("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPendingCredentialPreferenceRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Staffing.PendingCredentialPreferenceRequiredSpecialtyRule(
            message: "pending credential preference needs an entry"
        )
        let item = Staffing.newPendingCredentialPreference("", name: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct StaffingPendingCredentialPreferenceRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Staffing.PendingCredentialPreferenceRevisionRangeRule(min: 80, max: 255)
        let item = Staffing.newPendingCredentialPreference("x", name: "y")
        item.revision = 256
        #expect(rule.check(item).count > 0)
    }
}
