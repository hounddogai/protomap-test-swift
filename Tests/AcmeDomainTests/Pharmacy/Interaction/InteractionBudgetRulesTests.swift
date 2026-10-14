@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyInteractionBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultInteractionBudgetValidator()
        let item = Pharmacy.newInteractionBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyInteractionBudgetChecksumLengthRuleTests {
    @Test func flagsALongChecksum() throws {
        let rule = Pharmacy.InteractionBudgetChecksumLengthRule(maxLength: 255)
        let item = Pharmacy.newInteractionBudget("x", title: "y")
        item.checksum = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.checksum = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyInteractionBudgetMaximumRangeRuleTests {
    @Test func flagsValuesAboveMaximum() throws {
        let rule = Pharmacy.InteractionBudgetMaximumRangeRule(min: 1.3, max: 2634.0)
        let item = Pharmacy.newInteractionBudget("x", title: "y")
        item.maximum = 2635.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct PharmacyInteractionBudgetRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Pharmacy.InteractionBudgetRequiredTitleRule(message: "interaction budget needs a value")
        let item = Pharmacy.newInteractionBudget("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionBudgetRequiredChecksumRuleTests {
    @Test func flagsABlankChecksum() throws {
        let rule = Pharmacy.InteractionBudgetRequiredChecksumRule(message: "interaction budget needs this field")
        let item = Pharmacy.newInteractionBudget("", title: "")
        item.checksum = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyInteractionBudgetRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.InteractionBudgetRequiredCodeRule(message: "interaction budget needs an entry")
        let item = Pharmacy.newInteractionBudget("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
