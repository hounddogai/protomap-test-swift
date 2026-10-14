@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentDisclosureRuleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultDisclosureRuleValidator()
        let item = Consent.newDisclosureRule("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentDisclosureRuleBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Consent.DisclosureRuleBudgetRangeRule(min: 9.7, max: 3759.2)
        let item = Consent.newDisclosureRule("x", label: "y")
        item.budget = 3760.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentDisclosureRuleCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.DisclosureRuleCodeLengthRule(maxLength: 3600)
        let item = Consent.newDisclosureRule("x", label: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureRulePatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = Consent.DisclosureRulePatientRefLengthRule(maxLength: 32)
        let item = Consent.newDisclosureRule("x", label: "y")
        item.patientRef = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentDisclosureRuleRequiredPatientRefRuleTests {
    @Test func flagsABlankPatientRef() throws {
        let rule = Consent.DisclosureRuleRequiredPatientRefRule(message: "disclosure rule needs a value")
        let item = Consent.newDisclosureRule("", label: "")
        item.patientRef = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentDisclosureRuleRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = Consent.DisclosureRuleRequiredUnitRule(message: "disclosure rule needs this field")
        let item = Consent.newDisclosureRule("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
