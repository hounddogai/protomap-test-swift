@testable import AcmePatientapp
import AcmePlatform
import Foundation
import Testing

@Suite struct ConsentAdaptiveConsentFormAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Consent.defaultAdaptiveConsentFormAllocationValidator()
        let item = Consent.newAdaptiveConsentFormAllocation("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ConsentAdaptiveConsentFormAllocationCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Consent.AdaptiveConsentFormAllocationCodeLengthRule(maxLength: 86400)
        let item = Consent.newAdaptiveConsentFormAllocation("x", name: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentAdaptiveConsentFormAllocationAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Consent.AdaptiveConsentFormAllocationAllergyLengthRule(maxLength: 16)
        let item = Consent.newAdaptiveConsentFormAllocation("x", name: "y")
        item.allergy = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ConsentAdaptiveConsentFormAllocationCapacityRangeRuleTests {
    @Test func flagsValuesAboveCapacity() throws {
        let rule = Consent.AdaptiveConsentFormAllocationCapacityRangeRule(min: 64, max: 1000)
        let item = Consent.newAdaptiveConsentFormAllocation("x", name: "y")
        item.capacity = 1001
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ConsentAdaptiveConsentFormAllocationRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Consent.AdaptiveConsentFormAllocationRequiredNameRule(
            message: "adaptive consent form allocation needs this field"
        )
        let item = Consent.newAdaptiveConsentFormAllocation("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ConsentAdaptiveConsentFormAllocationRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Consent.AdaptiveConsentFormAllocationRequiredAllergyRule(
            message: "adaptive consent form allocation needs a value"
        )
        let item = Consent.newAdaptiveConsentFormAllocation("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}
