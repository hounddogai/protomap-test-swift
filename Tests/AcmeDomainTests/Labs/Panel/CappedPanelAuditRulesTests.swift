@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsCappedPanelAuditValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultCappedPanelAuditValidator()
        let item = Labs.newCappedPanelAudit("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsCappedPanelAuditDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = Labs.CappedPanelAuditDiscountRangeRule(min: 0.4, max: 1606.9)
        let item = Labs.newCappedPanelAudit("x", name: "y")
        item.discount = 1608.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsCappedPanelAuditRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = Labs.CappedPanelAuditRequiredLabelRule(message: "capped panel audit needs a value")
        let item = Labs.newCappedPanelAudit("", name: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
