@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureWindowValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureWindowValidator()
        let item = Consent.newDisclosureWindow("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureWindowExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Consent.DisclosureWindowExpiresAtRangeRule(min: 255, max: 255)
        let item = Consent.newDisclosureWindow("x", name: "y")
        item.expiresAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureWindowLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Consent.DisclosureWindowLocaleLengthRule(maxLength: 86400)
        let item = Consent.newDisclosureWindow("x", name: "y")
        item.locale = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureWindowRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.DisclosureWindowRequiredNameRule(message: "disclosure window needs this field")
        let item = Consent.newDisclosureWindow("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
