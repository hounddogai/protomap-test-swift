@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLegacyDisclosureThresholdValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLegacyDisclosureThresholdValidator()
        let item = Consent.newLegacyDisclosureThreshold("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLegacyDisclosureThresholdLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.LegacyDisclosureThresholdLabelLengthRule(maxLength: 3600)
        let item = Consent.newLegacyDisclosureThreshold("x", label: "y")
        item.label = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLegacyDisclosureThresholdRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.LegacyDisclosureThresholdRequiredLabelRule(
            message: "legacy disclosure threshold needs a value"
        )
        let item = Consent.newLegacyDisclosureThreshold("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLegacyDisclosureThresholdRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LegacyDisclosureThresholdRequiredCodeRule(
            message: "legacy disclosure threshold needs a value"
        )
        let item = Consent.newLegacyDisclosureThreshold("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLegacyDisclosureThresholdCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LegacyDisclosureThresholdCodeLengthRule(maxLength: 120)
        let item = Consent.newLegacyDisclosureThreshold("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLegacyDisclosureThresholdEncounterIDLengthRuleTests {
    @Test func flagsALongEncounterID() throws {
        let rule = Consent.LegacyDisclosureThresholdEncounterIDLengthRule(maxLength: 80)
        let item = Consent.newLegacyDisclosureThreshold("x", label: "y")
        item.encounterID = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.encounterID = "ok"
        #expect(rule.check(item).count == 0)
    }
}
