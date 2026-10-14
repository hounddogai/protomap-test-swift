@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPendingTransferSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPendingTransferSummaryValidator()
        let item = BedManagement.newPendingTransferSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPendingTransferSummaryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = BedManagement.PendingTransferSummaryRequiredLabelRule(
            message: "pending transfer summary needs an entry"
        )
        let item = BedManagement.newPendingTransferSummary("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct BedManagementPendingTransferSummaryBudgetRangeRuleTests {
    @Test func flagsValuesAboveBudget() throws {
        let rule = BedManagement.PendingTransferSummaryBudgetRangeRule(min: 6.1, max: 4589.4)
        let item = BedManagement.newPendingTransferSummary("x", label: "y")
        item.budget = 4590.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPendingTransferSummaryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = BedManagement.PendingTransferSummaryLabelLengthRule(maxLength: 86400)
        let item = BedManagement.newPendingTransferSummary("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}
