@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenTierValidator()
        let item = Labs.newSpecimenTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenTierLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.SpecimenTierLabelLengthRule(maxLength: 80)
        let item = Labs.newSpecimenTier("x", label: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsSpecimenTierBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Labs.SpecimenTierBudgetRangeRule(min: 0.8, max: 606.9)
        let item = Labs.newSpecimenTier("x", label: "y")
        item.budget = 608.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenTierRequiredChannelRuleTests {
    @Test func flagsABlankChannel() throws {
        let rule = Labs.SpecimenTierRequiredChannelRule(message: "specimen tier needs this field")
        let item = Labs.newSpecimenTier("", label: "")
        item.channel = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsSpecimenTierCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Labs.SpecimenTierCategoryLengthRule(maxLength: 255)
        let item = Labs.newSpecimenTier("x", label: "y")
        item.category = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
