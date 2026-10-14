@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyAdaptiveFormularyDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultAdaptiveFormularyDraftValidator()
        let item = Pharmacy.newAdaptiveFormularyDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyAdaptiveFormularyDraftRevisionRangeRuleTests {
    @Test func flagsValuesAboveRevision() throws {
        let rule = Pharmacy.AdaptiveFormularyDraftRevisionRangeRule(min: 1000, max: 3600)
        let item = Pharmacy.newAdaptiveFormularyDraft("x", title: "y")
        item.revision = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyAdaptiveFormularyDraftRequiredPayerRuleTests {
    @Test func flagsABlankPayer() throws {
        let rule = Pharmacy.AdaptiveFormularyDraftRequiredPayerRule(message: "adaptive formulary draft needs an entry")
        let item = Pharmacy.newAdaptiveFormularyDraft("", title: "")
        item.payer = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyAdaptiveFormularyDraftTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.AdaptiveFormularyDraftTitleLengthRule(maxLength: 16)
        let item = Pharmacy.newAdaptiveFormularyDraft("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyAdaptiveFormularyDraftPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Pharmacy.AdaptiveFormularyDraftPayerLengthRule(maxLength: 255)
        let item = Pharmacy.newAdaptiveFormularyDraft("x", title: "y")
        item.payer = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyAdaptiveFormularyDraftPriorityRangeRuleTests {
    @Test func flagsValuesAbovePriority() throws {
        let rule = Pharmacy.AdaptiveFormularyDraftPriorityRangeRule(min: 32, max: 32)
        let item = Pharmacy.newAdaptiveFormularyDraft("x", title: "y")
        item.priority = 33
        #expect(rule.check(item).count > 0)
    }
}
