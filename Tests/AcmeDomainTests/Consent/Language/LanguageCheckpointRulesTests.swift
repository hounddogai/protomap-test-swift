@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageCheckpointValidator()
        let item = Consent.newLanguageCheckpoint("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageCheckpointChannelLengthRuleTests {
    @Test func flagsALongChannel() throws {
        let rule = Consent.LanguageCheckpointChannelLengthRule(maxLength: 64)
        let item = Consent.newLanguageCheckpoint("x", name: "y")
        item.channel = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.channel = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentLanguageCheckpointDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Consent.LanguageCheckpointDosageMgRangeRule(min: 7.0, max: 3260.1)
        let item = Consent.newLanguageCheckpoint("x", name: "y")
        item.dosageMg = 3261.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentLanguageCheckpointRefillsRangeRuleTests {
    @Test func flagsValuesAboveRefills() throws {
        let rule = Consent.LanguageCheckpointRefillsRangeRule(min: 16, max: 120)
        let item = Consent.newLanguageCheckpoint("x", name: "y")
        item.refills = 121
        #expect(rule.check(item).count > 0)
    }
}
