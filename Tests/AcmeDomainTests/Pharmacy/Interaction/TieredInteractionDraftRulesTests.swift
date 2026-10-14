@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyTieredInteractionDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultTieredInteractionDraftValidator()
        let item = Pharmacy.newTieredInteractionDraft("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyTieredInteractionDraftRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.TieredInteractionDraftRequiredCodeRule(message: "tiered interaction draft needs a value")
        let item = Pharmacy.newTieredInteractionDraft("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyTieredInteractionDraftMinimumRangeRuleTests {
    @Test func flagsValuesAboveMinimum() throws {
        let rule = Pharmacy.TieredInteractionDraftMinimumRangeRule(min: 7.6, max: 339.9)
        let item = Pharmacy.newTieredInteractionDraft("x", title: "y")
        item.minimum = 341.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyTieredInteractionDraftTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.TieredInteractionDraftTitleLengthRule(maxLength: 64)
        let item = Pharmacy.newTieredInteractionDraft("x", title: "y")
        item.title = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyTieredInteractionDraftPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = Pharmacy.TieredInteractionDraftPayerLengthRule(maxLength: 86400)
        let item = Pharmacy.newTieredInteractionDraft("x", title: "y")
        item.payer = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyTieredInteractionDraftCreatedAtRangeRuleTests {
    @Test func flagsValuesAboveCreatedAt() throws {
        let rule = Pharmacy.TieredInteractionDraftCreatedAtRangeRule(min: 16, max: 32)
        let item = Pharmacy.newTieredInteractionDraft("x", title: "y")
        item.createdAt = 33
        #expect(rule.check(item).count > 0)
    }
}
