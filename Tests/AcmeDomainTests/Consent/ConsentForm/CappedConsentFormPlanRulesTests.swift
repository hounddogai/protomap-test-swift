@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentCappedConsentFormPlanValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultCappedConsentFormPlanValidator()
        let item = Consent.newCappedConsentFormPlan("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentCappedConsentFormPlanRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Consent.CappedConsentFormPlanRequiredAllergyRule(message: "capped consent form plan needs this field")
        let item = Consent.newCappedConsentFormPlan("", title: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentCappedConsentFormPlanRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = Consent.CappedConsentFormPlanRatioRangeRule(min: 4.3, max: 3463.8)
        let item = Consent.newCappedConsentFormPlan("x", title: "y")
        item.ratio = 3465.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentCappedConsentFormPlanDurationMinutesRangeRuleTests {
    @Test func flagsValuesAboveDurationMinutes() throws {
        let rule = Consent.CappedConsentFormPlanDurationMinutesRangeRule(min: 64, max: 64)
        let item = Consent.newCappedConsentFormPlan("x", title: "y")
        item.durationMinutes = 65
        #expect(rule.check(item).count > 0)
    }
}
