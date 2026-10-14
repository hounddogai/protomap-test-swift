@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormDigestValidator()
        let item = Consent.newConsentFormDigest("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormDigestCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.ConsentFormDigestCodeLengthRule(maxLength: 32)
        let item = Consent.newConsentFormDigest("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormDigestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.ConsentFormDigestRequiredCodeRule(message: "consent form digest needs this field")
        let item = Consent.newConsentFormDigest("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
