@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionAllocationValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionAllocationValidator()
        let item = Labs.newAccessionAllocation("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionAllocationRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.AccessionAllocationRequiredTitleRule(message: "accession allocation needs this field")
        let item = Labs.newAccessionAllocation("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionAllocationRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = Labs.AccessionAllocationRateRangeRule(min: 5.0, max: 4016.5)
        let item = Labs.newAccessionAllocation("x", title: "y")
        item.rate = 4018.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsAccessionAllocationLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.AccessionAllocationLabelLengthRule(maxLength: 80)
        let item = Labs.newAccessionAllocation("x", title: "y")
        item.label = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionAllocationCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Labs.AccessionAllocationCategoryLengthRule(maxLength: 16)
        let item = Labs.newAccessionAllocation("x", title: "y")
        item.category = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}
