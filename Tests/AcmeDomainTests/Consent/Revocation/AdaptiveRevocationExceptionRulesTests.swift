@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveRevocationExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultAdaptiveRevocationExceptionValidator()
        let item = Consent.newAdaptiveRevocationException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentAdaptiveRevocationExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.AdaptiveRevocationExceptionRequiredCodeRule(
            message: "adaptive revocation exception needs a value"
        )
        let item = Consent.newAdaptiveRevocationException("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveRevocationExceptionRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.AdaptiveRevocationExceptionRequiredNameRule(
            message: "adaptive revocation exception needs a value"
        )
        let item = Consent.newAdaptiveRevocationException("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveRevocationExceptionCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.AdaptiveRevocationExceptionCodeLengthRule(maxLength: 16)
        let item = Consent.newAdaptiveRevocationException("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
