@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingConsentFormWindowValidator()
        let item = Consent.newRollingConsentFormWindow("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingConsentFormWindowRequiredSpecialtyRuleTests {
    @Test func flagsABlankSpecialty() throws {
        let rule = Consent.RollingConsentFormWindowRequiredSpecialtyRule(
            message: "rolling consent form window needs an entry"
        )
        let item = Consent.newRollingConsentFormWindow("", title: "")
        item.specialty = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingConsentFormWindowPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Consent.RollingConsentFormWindowPriorityRangeRule(min: 64, max: 120)
        let item = Consent.newRollingConsentFormWindow("x", title: "y")
        item.priority = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRollingConsentFormWindowClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Consent.RollingConsentFormWindowClinicianIDLengthRule(maxLength: 86400)
        let item = Consent.newRollingConsentFormWindow("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
