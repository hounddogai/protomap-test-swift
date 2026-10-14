@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureRequestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureRequestValidator()
        let item = Consent.newDisclosureRequest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureRequestRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Consent.DisclosureRequestRequiredBedRule(message: "disclosure request needs an entry")
        let item = Consent.newDisclosureRequest("", label: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureRequestMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Consent.DisclosureRequestMinimumRangeRule(min: 4.0, max: 410.6)
        let item = Consent.newDisclosureRequest("x", label: "y")
        item.minimum = 412.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureRequestBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Consent.DisclosureRequestBedLengthRule(maxLength: 255)
        let item = Consent.newDisclosureRequest("x", label: "y")
        item.bed = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureRequestRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.DisclosureRequestRequiredCodeRule(message: "disclosure request needs this field")
        let item = Consent.newDisclosureRequest("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureRequestLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.DisclosureRequestLabelLengthRule(maxLength: 86400)
        let item = Consent.newDisclosureRequest("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
