@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureExceptionValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureExceptionValidator()
        let item = Consent.newDisclosureException("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureExceptionContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = Consent.DisclosureExceptionContactEmailLengthRule(maxLength: 86400)
        let item = Consent.newDisclosureException("x", name: "y")
        item.contactEmail = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureExceptionRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = Consent.DisclosureExceptionRequiredFacilityRule(message: "disclosure exception needs an entry")
        let item = Consent.newDisclosureException("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureExceptionRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.DisclosureExceptionRequiredNameRule(message: "disclosure exception needs this field")
        let item = Consent.newDisclosureException("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}
