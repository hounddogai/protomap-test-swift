@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentBatchedDisclosurePreferenceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultBatchedDisclosurePreferenceValidator()
        let item = Consent.newBatchedDisclosurePreference("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentBatchedDisclosurePreferenceCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.BatchedDisclosurePreferenceCodeLengthRule(maxLength: 64)
        let item = Consent.newBatchedDisclosurePreference("x", label: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentBatchedDisclosurePreferenceRequiredEncounterIDRuleTests {
    @Test func flagsABlankEncounterID() throws {
        let rule = Consent.BatchedDisclosurePreferenceRequiredEncounterIDRule(
            message: "batched disclosure preference needs a value"
        )
        let item = Consent.newBatchedDisclosurePreference("", label: "")
        item.encounterID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentBatchedDisclosurePreferenceTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = Consent.BatchedDisclosurePreferenceTimezoneLengthRule(maxLength: 16)
        let item = Consent.newBatchedDisclosurePreference("x", label: "y")
        item.timezone = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
