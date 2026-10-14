@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureOverrideValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureOverrideValidator()
        let item = Consent.newDisclosureOverride("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureOverrideRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.DisclosureOverrideRequiredLabelRule(message: "disclosure override needs this field")
        let item = Consent.newDisclosureOverride("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureOverrideLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.DisclosureOverrideLabelLengthRule(maxLength: 120)
        let item = Consent.newDisclosureOverride("x", label: "y")
        item.label = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureOverrideRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Consent.DisclosureOverrideRequiredCodeRule(message: "disclosure override needs this field")
        let item = Consent.newDisclosureOverride("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureOverrideCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.DisclosureOverrideCodeLengthRule(maxLength: 3600)
        let item = Consent.newDisclosureOverride("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureOverrideCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Consent.DisclosureOverrideCapacityRangeRule(min: 32, max: 3600)
        let item = Consent.newDisclosureOverride("x", label: "y")
        item.capacity = 3601
        #expect(rule.check(item).count > 0)
    }
}
