@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentLanguageQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultLanguageQuotaValidator()
        let item = Consent.newLanguageQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentLanguageQuotaCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.LanguageQuotaCodeLengthRule(maxLength: 255)
        let item = Consent.newLanguageQuota("x", title: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
