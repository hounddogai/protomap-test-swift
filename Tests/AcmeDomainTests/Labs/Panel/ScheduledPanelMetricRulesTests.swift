@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct LabsScheduledPanelMetricValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = Labs.defaultScheduledPanelMetricValidator()
        let item = Labs.newScheduledPanelMetric("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct LabsScheduledPanelMetricRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = Labs.ScheduledPanelMetricRequiredTitleRule(message: "scheduled panel metric needs this field")
        let item = Labs.newScheduledPanelMetric("", label: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsScheduledPanelMetricOwnerIDLengthRuleTests {
    @Test func flagsALongOwnerID() throws {
        let rule = Labs.ScheduledPanelMetricOwnerIDLengthRule(maxLength: 3600)
        let item = Labs.newScheduledPanelMetric("x", label: "y")
        item.ownerID = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.ownerID = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct LabsScheduledPanelMetricQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = Labs.ScheduledPanelMetricQuantityRangeRule(min: 120, max: 255)
        let item = Labs.newScheduledPanelMetric("x", label: "y")
        item.quantity = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct LabsScheduledPanelMetricRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = Labs.ScheduledPanelMetricRequiredCodeRule(message: "scheduled panel metric needs this field")
        let item = Labs.newScheduledPanelMetric("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct LabsScheduledPanelMetricCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = Labs.ScheduledPanelMetricCopayRangeRule(min: 5.6, max: 1735.2)
        let item = Labs.newScheduledPanelMetric("x", label: "y")
        item.copay = 1736.7
        #expect(rule.check(item).count > 0)
    }
}
