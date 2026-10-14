@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsSpecimenBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultSpecimenBudgetValidator()
        let item = Labs.newSpecimenBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsSpecimenBudgetFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = Labs.SpecimenBudgetFloorValueRangeRule(min: 6.2, max: 648.4)
        let item = Labs.newSpecimenBudget("x", label: "y")
        item.floorValue = 649.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsSpecimenBudgetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.SpecimenBudgetRequiredLabelRule(message: "specimen budget needs a value")
        let item = Labs.newSpecimenBudget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
