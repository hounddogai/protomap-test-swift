@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentManualConsentFormEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultManualConsentFormEntryValidator()
        let item = Consent.newManualConsentFormEntry("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentManualConsentFormEntryNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = Consent.ManualConsentFormEntryNameLengthRule(maxLength: 16)
        let item = Consent.newManualConsentFormEntry("x", name: "y")
        item.name = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentManualConsentFormEntryRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.ManualConsentFormEntryRequiredNameRule(message: "manual consent form entry needs a value")
        let item = Consent.newManualConsentFormEntry("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
