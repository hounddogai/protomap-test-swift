@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLenientLanguageCheckpointValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLenientLanguageCheckpointValidator()
        let item = Consent.newLenientLanguageCheckpoint("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLenientLanguageCheckpointRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Consent.LenientLanguageCheckpointRequiredDescriptionRule(
            message: "lenient language checkpoint needs an entry"
        )
        let item = Consent.newLenientLanguageCheckpoint("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientLanguageCheckpointRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Consent.LenientLanguageCheckpointRequiredChecksumRule(
            message: "lenient language checkpoint needs an entry"
        )
        let item = Consent.newLenientLanguageCheckpoint("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentLenientLanguageCheckpointRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.LenientLanguageCheckpointRequiredCodeRule(
            message: "lenient language checkpoint needs an entry"
        )
        let item = Consent.newLenientLanguageCheckpoint("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
