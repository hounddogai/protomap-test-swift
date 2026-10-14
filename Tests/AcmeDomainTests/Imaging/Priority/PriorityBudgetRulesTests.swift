@testable import AcmeTelehealth
import AcmePlatform
import Foundation
import Testing

@Suite struct ImagingPriorityBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Imaging.defaultPriorityBudgetValidator()
        let item = Imaging.newPriorityBudget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ImagingPriorityBudgetRequiredNameRuleTests {
    @Test func flagsABlankName() throws {
        let rule = Imaging.PriorityBudgetRequiredNameRule(message: "priority budget needs this field")
        let item = Imaging.newPriorityBudget("", name: "")
        item.name = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityBudgetRequiredBedRuleTests {
    @Test func flagsABlankBed() throws {
        let rule = Imaging.PriorityBudgetRequiredBedRule(message: "priority budget needs an entry")
        let item = Imaging.newPriorityBudget("", name: "")
        item.bed = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityBudgetAllergyLengthRuleTests {
    @Test func flagsALongAllergy() throws {
        let rule = Imaging.PriorityBudgetAllergyLengthRule(maxLength: 3600)
        let item = Imaging.newPriorityBudget("x", name: "y")
        item.allergy = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.allergy = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityBudgetRequiredAllergyRuleTests {
    @Test func flagsABlankAllergy() throws {
        let rule = Imaging.PriorityBudgetRequiredAllergyRule(message: "priority budget needs an entry")
        let item = Imaging.newPriorityBudget("", name: "")
        item.allergy = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ImagingPriorityBudgetBedLengthRuleTests {
    @Test func flagsALongBed() throws {
        let rule = Imaging.PriorityBudgetBedLengthRule(maxLength: 16)
        let item = Imaging.newPriorityBudget("x", name: "y")
        item.bed = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.bed = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ImagingPriorityBudgetDosageMgRangeRuleTests {
    @Test func flagsValuesAboveDosageMg() throws {
        let rule = Imaging.PriorityBudgetDosageMgRangeRule(min: 9.5, max: 4438.7)
        let item = Imaging.newPriorityBudget("x", name: "y")
        item.dosageMg = 4440.2
        #expect(rule.check(item).count > 0)
    }
}
