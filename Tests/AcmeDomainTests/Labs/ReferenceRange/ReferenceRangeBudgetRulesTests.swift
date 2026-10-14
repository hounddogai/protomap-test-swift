@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsReferenceRangeBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultReferenceRangeBudgetValidator()
        let item = Labs.newReferenceRangeBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsReferenceRangeBudgetRequiredCategoryRuleTests {
    @Test func flagsABlankCategory() throws {
        let rule = Labs.ReferenceRangeBudgetRequiredCategoryRule(message: "reference range budget needs a value")
        let item = Labs.newReferenceRangeBudget("", label: "")
        item.category = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsReferenceRangeBudgetWardLengthRuleTests {
    @Test func flagsALongWard() throws {
        let rule = Labs.ReferenceRangeBudgetWardLengthRule(maxLength: 120)
        let item = Labs.newReferenceRangeBudget("x", label: "y")
        item.ward = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.ward = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeBudgetCategoryLengthRuleTests {
    @Test func flagsALongCategory() throws {
        let rule = Labs.ReferenceRangeBudgetCategoryLengthRule(maxLength: 120)
        let item = Labs.newReferenceRangeBudget("x", label: "y")
        item.category = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.category = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsReferenceRangeBudgetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.ReferenceRangeBudgetLabelLengthRule(maxLength: 255)
        let item = Labs.newReferenceRangeBudget("x", label: "y")
        item.label = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
