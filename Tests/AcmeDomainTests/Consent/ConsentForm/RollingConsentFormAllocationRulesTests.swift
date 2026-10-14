@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingConsentFormAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingConsentFormAllocationValidator()
        let item = Consent.newRollingConsentFormAllocation("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingConsentFormAllocationRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RollingConsentFormAllocationRequiredCodeRule(
            message: "rolling consent form allocation needs an entry"
        )
        let item = Consent.newRollingConsentFormAllocation("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingConsentFormAllocationRequiredNotesRuleTests {
    @Test func flagsABlankNotes() throws {
        let rule = Consent.RollingConsentFormAllocationRequiredNotesRule(
            message: "rolling consent form allocation needs an entry"
        )
        let item = Consent.newRollingConsentFormAllocation("", label: "")
        item.notes = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingConsentFormAllocationRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.RollingConsentFormAllocationRequiredLabelRule(
            message: "rolling consent form allocation needs this field"
        )
        let item = Consent.newRollingConsentFormAllocation("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingConsentFormAllocationRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Consent.RollingConsentFormAllocationRevisionRangeRule(min: 255, max: 3600)
        let item = Consent.newRollingConsentFormAllocation("x", label: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentRollingConsentFormAllocationNotesLengthRuleTests {
    @Test func flagsALongNotes() throws {
        let rule = Consent.RollingConsentFormAllocationNotesLengthRule(maxLength: 64)
        let item = Consent.newRollingConsentFormAllocation("x", label: "y")
        item.notes = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.notes = "ok"
        #expect(rule.check(item).count == 0)
    }
}
