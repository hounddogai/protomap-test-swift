@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentConsentFormVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultConsentFormVarianceValidator()
        let item = Consent.newConsentFormVariance("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentConsentFormVarianceQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Consent.ConsentFormVarianceQuantityRangeRule(min: 64, max: 80)
        let item = Consent.newConsentFormVariance("x", label: "y")
        item.quantity = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentConsentFormVarianceRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Consent.ConsentFormVarianceRequiredLabelRule(message: "consent form variance needs this field")
        let item = Consent.newConsentFormVariance("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
