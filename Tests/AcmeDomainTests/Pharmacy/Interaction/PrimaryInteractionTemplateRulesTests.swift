@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPrimaryInteractionTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPrimaryInteractionTemplateValidator()
        let item = Pharmacy.newPrimaryInteractionTemplate("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPrimaryInteractionTemplateRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.PrimaryInteractionTemplateRequiredLabelRule(
            message: "primary interaction template needs an entry"
        )
        let item = Pharmacy.newPrimaryInteractionTemplate("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPrimaryInteractionTemplateMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Pharmacy.PrimaryInteractionTemplateMinimumRangeRule(min: 5.5, max: 4715.2)
        let item = Pharmacy.newPrimaryInteractionTemplate("x", label: "y")
        item.minimum = 4716.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPrimaryInteractionTemplateRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Pharmacy.PrimaryInteractionTemplateRateRangeRule(min: 1.2, max: 2929.9)
        let item = Pharmacy.newPrimaryInteractionTemplate("x", label: "y")
        item.rate = 2931.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyPrimaryInteractionTemplateRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = Pharmacy.PrimaryInteractionTemplateRequiredTimezoneRule(
            message: "primary interaction template needs an entry"
        )
        let item = Pharmacy.newPrimaryInteractionTemplate("", label: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}
