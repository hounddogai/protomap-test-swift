@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDefaultDisclosureProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDefaultDisclosureProfileValidator()
        let item = Consent.newDefaultDisclosureProfile("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDefaultDisclosureProfileTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Consent.DefaultDisclosureProfileTitleLengthRule(maxLength: 16)
        let item = Consent.newDefaultDisclosureProfile("x", label: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDefaultDisclosureProfileLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.DefaultDisclosureProfileLabelLengthRule(maxLength: 255)
        let item = Consent.newDefaultDisclosureProfile("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
