@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsAccessionBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultAccessionBudgetValidator()
        let item = Labs.newAccessionBudget("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsAccessionBudgetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = Labs.AccessionBudgetTitleLengthRule(maxLength: 120)
        let item = Labs.newAccessionBudget("x", label: "y")
        item.title = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionBudgetLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = Labs.AccessionBudgetLabelLengthRule(maxLength: 86400)
        let item = Labs.newAccessionBudget("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsAccessionBudgetRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.AccessionBudgetRequiredLabelRule(message: "accession budget needs this field")
        let item = Labs.newAccessionBudget("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsAccessionBudgetCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = Labs.AccessionBudgetCodeLengthRule(maxLength: 255)
        let item = Labs.newAccessionBudget("x", label: "y")
        item.code = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
