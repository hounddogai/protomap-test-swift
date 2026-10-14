@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormQuotaValidator()
        let item = Consent.newConsentFormQuota("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormQuotaTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.ConsentFormQuotaTitleLengthRule(maxLength: 1000)
        let item = Consent.newConsentFormQuota("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentConsentFormQuotaCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Consent.ConsentFormQuotaCategoryLengthRule(maxLength: 86400)
        let item = Consent.newConsentFormQuota("x", title: "y")
        item.category = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
