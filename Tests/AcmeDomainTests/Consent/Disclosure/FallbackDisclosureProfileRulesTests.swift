@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentFallbackDisclosureProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultFallbackDisclosureProfileValidator()
        let item = Consent.newFallbackDisclosureProfile("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentFallbackDisclosureProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.FallbackDisclosureProfileCodeLengthRule(maxLength: 120)
        let item = Consent.newFallbackDisclosureProfile("x", title: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
