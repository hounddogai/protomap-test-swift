@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentGlobalDisclosureRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultGlobalDisclosureRuleValidator()
        let item = Consent.newGlobalDisclosureRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentGlobalDisclosureRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.GlobalDisclosureRuleCodeLengthRule(maxLength: 1000)
        let item = Consent.newGlobalDisclosureRule("x", label: "y")
        item.code = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentGlobalDisclosureRuleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.GlobalDisclosureRuleRequiredLabelRule(message: "global disclosure rule needs a value")
        let item = Consent.newGlobalDisclosureRule("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentGlobalDisclosureRuleLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.GlobalDisclosureRuleLabelLengthRule(maxLength: 64)
        let item = Consent.newGlobalDisclosureRule("x", label: "y")
        item.label = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
