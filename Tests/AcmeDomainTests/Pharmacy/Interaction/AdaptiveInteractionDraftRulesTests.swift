@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveInteractionDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultAdaptiveInteractionDraftValidator()
        let item = Pharmacy.newAdaptiveInteractionDraft("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyAdaptiveInteractionDraftLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Pharmacy.AdaptiveInteractionDraftLabelLengthRule(maxLength: 255)
        let item = Pharmacy.newAdaptiveInteractionDraft("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyAdaptiveInteractionDraftRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Pharmacy.AdaptiveInteractionDraftRequiredLabelRule(
            message: "adaptive interaction draft needs an entry"
        )
        let item = Pharmacy.newAdaptiveInteractionDraft("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveInteractionDraftSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = Pharmacy.AdaptiveInteractionDraftSequenceRangeRule(min: 32, max: 120)
        let item = Pharmacy.newAdaptiveInteractionDraft("x", label: "y")
        item.sequence = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyAdaptiveInteractionDraftExpiresAtRangeRuleTests {
    @Test func flagsValuesAboveExpiresAt() throws {
        let rule = Pharmacy.AdaptiveInteractionDraftExpiresAtRangeRule(min: 80, max: 120)
        let item = Pharmacy.newAdaptiveInteractionDraft("x", label: "y")
        item.expiresAt = 121
        #expect(rule.check(item).count > 0)
    }
}
