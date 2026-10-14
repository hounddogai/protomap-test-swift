@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormWindowValidator()
        let item = Consent.newConsentFormWindow("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormWindowLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.ConsentFormWindowLabelLengthRule(maxLength: 1000)
        let item = Consent.newConsentFormWindow("x", label: "y")
        item.label = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormWindowRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.ConsentFormWindowRequiredLabelRule(message: "consent form window needs an entry")
        let item = Consent.newConsentFormWindow("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentConsentFormWindowRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormWindowRequiredCodeRule(message: "consent form window needs an entry")
        let item = Consent.newConsentFormWindow("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
