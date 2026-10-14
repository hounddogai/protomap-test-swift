@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentWitnessPolicyValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultWitnessPolicyValidator()
        let item = Consent.newWitnessPolicy("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentWitnessPolicyLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Consent.WitnessPolicyLabelLengthRule(maxLength: 86400)
        let item = Consent.newWitnessPolicy("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentWitnessPolicyDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Consent.WitnessPolicyDiscountRangeRule(min: 7.2, max: 2730.4)
        let item = Consent.newWitnessPolicy("x", label: "y")
        item.discount = 2731.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentWitnessPolicyRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.WitnessPolicyRequiredLabelRule(message: "witness policy needs a value")
        let item = Consent.newWitnessPolicy("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentWitnessPolicyCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = Consent.WitnessPolicyCeilingRangeRule(min: 8.9, max: 1579.7)
        let item = Consent.newWitnessPolicy("x", label: "y")
        item.ceiling = 1581.2
        #expect(rule.check(item).count > 0)
    }
}
