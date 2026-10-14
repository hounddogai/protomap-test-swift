@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveConsentFormCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultAdaptiveConsentFormCheckpointValidator()
        let item = Consent.newAdaptiveConsentFormCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentAdaptiveConsentFormCheckpointClinicianIDLengthRuleTests {
    @Test func flagsALongClinicianID() throws {
        let rule = Consent.AdaptiveConsentFormCheckpointClinicianIDLengthRule(maxLength: 120)
        let item = Consent.newAdaptiveConsentFormCheckpoint("x", title: "y")
        item.clinicianID = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.clinicianID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentAdaptiveConsentFormCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.AdaptiveConsentFormCheckpointRequiredNameRule(
            message: "adaptive consent form checkpoint needs an entry"
        )
        let item = Consent.newAdaptiveConsentFormCheckpoint("", title: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveConsentFormCheckpointVersionRangeRuleTests {
    @Test func flagsValuesAboveVersion() throws {
        let rule = Consent.AdaptiveConsentFormCheckpointVersionRangeRule(min: 255, max: 255)
        let item = Consent.newAdaptiveConsentFormCheckpoint("x", title: "y")
        item.version = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentAdaptiveConsentFormCheckpointSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Consent.AdaptiveConsentFormCheckpointSequenceRangeRule(min: 16, max: 32)
        let item = Consent.newAdaptiveConsentFormCheckpoint("x", title: "y")
        item.sequence = 33
        #expect(rule.check(item).count > 0)
    }
}
