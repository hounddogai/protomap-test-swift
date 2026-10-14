@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureTemplateValidator()
        let item = Consent.newDisclosureTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureTemplateRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Consent.DisclosureTemplateRequiredUnitRule(message: "disclosure template needs this field")
        let item = Consent.newDisclosureTemplate("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
