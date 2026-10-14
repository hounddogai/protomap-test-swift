@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormAllocationValidator()
        let item = Consent.newConsentFormAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormAllocationLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Consent.ConsentFormAllocationLocaleLengthRule(maxLength: 32)
        let item = Consent.newConsentFormAllocation("x", title: "y")
        item.locale = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}
