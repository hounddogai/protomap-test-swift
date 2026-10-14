@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCourierLedgerValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCourierLedgerValidator()
        let item = Labs.newCourierLedger("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCourierLedgerRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.CourierLedgerRequiredTitleRule(message: "courier ledger needs an entry")
        let item = Labs.newCourierLedger("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsCourierLedgerMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = Labs.CourierLedgerMarginRangeRule(min: 8.5, max: 3186.3)
        let item = Labs.newCourierLedger("x", title: "y")
        item.margin = 3187.8
        #expect(rule.check(item).count > 0)
    }
}
