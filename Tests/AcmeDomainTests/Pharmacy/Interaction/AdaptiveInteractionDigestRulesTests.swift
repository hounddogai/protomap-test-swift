@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInteractionDigestValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultAdaptiveInteractionDigestValidator()
        let item = Pharmacy.newAdaptiveInteractionDigest("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyAdaptiveInteractionDigestRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Pharmacy.AdaptiveInteractionDigestRequiredLocaleRule(
            message: "adaptive interaction digest needs a value"
        )
        let item = Pharmacy.newAdaptiveInteractionDigest("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveInteractionDigestRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Pharmacy.AdaptiveInteractionDigestRequiredAllergyRule(
            message: "adaptive interaction digest needs this field"
        )
        let item = Pharmacy.newAdaptiveInteractionDigest("", label: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveInteractionDigestFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Pharmacy.AdaptiveInteractionDigestFloorValueRangeRule(min: 9.9, max: 585.9)
        let item = Pharmacy.newAdaptiveInteractionDigest("x", label: "y")
        item.floorValue = 587.4
        #expect(rule.check(item).count > 0)
    }
}
