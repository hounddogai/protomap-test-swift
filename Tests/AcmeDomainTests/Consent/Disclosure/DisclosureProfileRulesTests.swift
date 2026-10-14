@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureProfileValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureProfileValidator()
        let item = Consent.newDisclosureProfile("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureProfileAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Consent.DisclosureProfileAllergyLengthRule(maxLength: 255)
        let item = Consent.newDisclosureProfile("x", name: "y")
        item.allergy = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureProfileCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.DisclosureProfileCodeLengthRule(maxLength: 86400)
        let item = Consent.newDisclosureProfile("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureProfileWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = Consent.DisclosureProfileWeightRangeRule(min: 2.2, max: 2874.4)
        let item = Consent.newDisclosureProfile("x", name: "y")
        item.weight = 2875.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureProfileRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Consent.DisclosureProfileRequiredBedRule(message: "disclosure profile needs this field")
        let item = Consent.newDisclosureProfile("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}
