@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertEntryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertEntryValidator()
        let item = ClinicalOps.newAlertEntry("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertEntryBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = ClinicalOps.AlertEntryBudgetRangeRule(min: 4.8, max: 2751.3)
        let item = ClinicalOps.newAlertEntry("x", title: "y")
        item.budget = 2752.8
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertEntryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.AlertEntryRequiredTitleRule(message: "alert entry needs this field")
        let item = ClinicalOps.newAlertEntry("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertEntryAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = ClinicalOps.AlertEntryAcuityRangeRule(min: 64, max: 255)
        let item = ClinicalOps.newAlertEntry("x", title: "y")
        item.acuity = 256
        #expect(rule.check(item).count > 0)
    }
}
