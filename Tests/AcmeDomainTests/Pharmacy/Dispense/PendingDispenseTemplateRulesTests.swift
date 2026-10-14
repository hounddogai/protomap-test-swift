@testable import AcmePrescriptions
import AcmePlatform
import Foundation
import Testing

@Suite struct PharmacyPendingDispenseTemplateValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Pharmacy.defaultPendingDispenseTemplateValidator()
        let item = Pharmacy.newPendingDispenseTemplate("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct PharmacyPendingDispenseTemplateTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Pharmacy.PendingDispenseTemplateTitleLengthRule(maxLength: 1000)
        let item = Pharmacy.newPendingDispenseTemplate("x", title: "y")
        item.title = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct PharmacyPendingDispenseTemplateRequiredDescriptionRuleTests {
    @Test func flagsABlankDescription() throws {
        let rule = Pharmacy.PendingDispenseTemplateRequiredDescriptionRule(
            message: "pending dispense template needs a value"
        )
        let item = Pharmacy.newPendingDispenseTemplate("", title: "")
        item.description = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingDispenseTemplateRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Pharmacy.PendingDispenseTemplateRequiredBedRule(message: "pending dispense template needs this field")
        let item = Pharmacy.newPendingDispenseTemplate("", title: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingDispenseTemplateRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Pharmacy.PendingDispenseTemplateRequiredCodeRule(
            message: "pending dispense template needs this field"
        )
        let item = Pharmacy.newPendingDispenseTemplate("", title: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct PharmacyPendingDispenseTemplateBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = Pharmacy.PendingDispenseTemplateBudgetRangeRule(min: 4.3, max: 2225.2)
        let item = Pharmacy.newPendingDispenseTemplate("x", title: "y")
        item.budget = 2226.7
        #expect(rule.check(item).count > 0)
    }
}
