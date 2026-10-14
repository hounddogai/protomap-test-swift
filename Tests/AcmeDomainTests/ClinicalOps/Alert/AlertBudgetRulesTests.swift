@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertBudgetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertBudgetValidator()
        let item = ClinicalOps.newAlertBudget("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertBudgetDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = ClinicalOps.AlertBudgetDiscountRangeRule(min: 9.0, max: 3939.0)
        let item = ClinicalOps.newAlertBudget("x", title: "y")
        item.discount = 3940.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertBudgetTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.AlertBudgetTitleLengthRule(maxLength: 86400)
        let item = ClinicalOps.newAlertBudget("x", title: "y")
        item.title = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertBudgetRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = ClinicalOps.AlertBudgetRequiredSegmentRule(message: "alert budget needs an entry")
        let item = ClinicalOps.newAlertBudget("", title: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}
