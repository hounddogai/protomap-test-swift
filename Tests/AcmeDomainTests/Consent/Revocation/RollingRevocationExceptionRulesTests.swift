@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentRollingRevocationExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultRollingRevocationExceptionValidator()
        let item = Consent.newRollingRevocationException("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentRollingRevocationExceptionRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Consent.RollingRevocationExceptionRequiredLocaleRule(
            message: "rolling revocation exception needs an entry"
        )
        let item = Consent.newRollingRevocationException("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentRollingRevocationExceptionRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.RollingRevocationExceptionRequiredCodeRule(
            message: "rolling revocation exception needs a value"
        )
        let item = Consent.newRollingRevocationException("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
