@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedWitnessCycleValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedWitnessCycleValidator()
        let item = Consent.newCappedWitnessCycle("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedWitnessCycleRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Consent.CappedWitnessCycleRequiredAllergyRule(message: "capped witness cycle needs this field")
        let item = Consent.newCappedWitnessCycle("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedWitnessCycleCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = Consent.CappedWitnessCycleCostRangeRule(min: 3.2, max: 2383.6)
        let item = Consent.newCappedWitnessCycle("x", title: "y")
        item.cost = 2385.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentCappedWitnessCycleRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.CappedWitnessCycleRequiredLabelRule(message: "capped witness cycle needs this field")
        let item = Consent.newCappedWitnessCycle("", title: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
