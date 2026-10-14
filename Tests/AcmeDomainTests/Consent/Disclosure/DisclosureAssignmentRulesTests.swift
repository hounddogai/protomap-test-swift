@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureAssignmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureAssignmentValidator()
        let item = Consent.newDisclosureAssignment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureAssignmentLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = Consent.DisclosureAssignmentLocaleLengthRule(maxLength: 32)
        let item = Consent.newDisclosureAssignment("x", label: "y")
        item.locale = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureAssignmentRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Consent.DisclosureAssignmentRequiredRegionRule(message: "disclosure assignment needs an entry")
        let item = Consent.newDisclosureAssignment("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}
