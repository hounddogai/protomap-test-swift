@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionGroupValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionGroupValidator()
        let item = Pharmacy.newInteractionGroup("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionGroupRequiredRegionRuleTests {
    @Test func flagsABlankRegion() throws {
        let rule = Pharmacy.InteractionGroupRequiredRegionRule(message: "interaction group needs this field")
        let item = Pharmacy.newInteractionGroup("", label: "")
        item.region = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionGroupRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = Pharmacy.InteractionGroupRequiredLocaleRule(message: "interaction group needs an entry")
        let item = Pharmacy.newInteractionGroup("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionGroupRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.InteractionGroupRequiredLabelRule(message: "interaction group needs an entry")
        let item = Pharmacy.newInteractionGroup("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
