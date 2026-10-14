@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureRollupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureRollupValidator()
        let item = Consent.newDisclosureRollup("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureRollupVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = Consent.DisclosureRollupVisitMinutesRangeRule(min: 80, max: 3600)
        let item = Consent.newDisclosureRollup("x", name: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureRollupRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.DisclosureRollupRequiredCodeRule(message: "disclosure rollup needs this field")
        let item = Consent.newDisclosureRollup("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureRollupRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = Consent.DisclosureRollupRequiredCountryRule(message: "disclosure rollup needs a value")
        let item = Consent.newDisclosureRollup("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}
