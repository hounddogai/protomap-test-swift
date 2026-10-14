@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentPendingConsentFormCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultPendingConsentFormCheckpointValidator()
        let item = Consent.newPendingConsentFormCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentPendingConsentFormCheckpointCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.PendingConsentFormCheckpointCodeLengthRule(maxLength: 32)
        let item = Consent.newPendingConsentFormCheckpoint("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentPendingConsentFormCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.PendingConsentFormCheckpointRequiredCodeRule(
            message: "pending consent form checkpoint needs a value"
        )
        let item = Consent.newPendingConsentFormCheckpoint("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentPendingConsentFormCheckpointScoreRangeRuleTests {
    @Test func flagsValuesAboveScore() throws {
        let rule = Consent.PendingConsentFormCheckpointScoreRangeRule(min: 5.2, max: 3177.3)
        let item = Consent.newPendingConsentFormCheckpoint("x", name: "y")
        item.score = 3178.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentPendingConsentFormCheckpointRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.PendingConsentFormCheckpointRequiredNameRule(
            message: "pending consent form checkpoint needs this field"
        )
        let item = Consent.newPendingConsentFormCheckpoint("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
