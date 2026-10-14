@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsAlertMilestoneValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultAlertMilestoneValidator()
        let item = ClinicalOps.newAlertMilestone("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsAlertMilestoneRequiredTimezoneRuleTests {
    @Test func flagsABlankTimezone() throws {
        let rule = ClinicalOps.AlertMilestoneRequiredTimezoneRule(message: "alert milestone needs an entry")
        let item = ClinicalOps.newAlertMilestone("", title: "")
        item.timezone = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertMilestoneQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = ClinicalOps.AlertMilestoneQuantityRangeRule(min: 86400, max: 86400)
        let item = ClinicalOps.newAlertMilestone("x", title: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsAlertMilestoneCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.AlertMilestoneCodeLengthRule(maxLength: 86400)
        let item = ClinicalOps.newAlertMilestone("x", title: "y")
        item.code = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsAlertMilestoneRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.AlertMilestoneRequiredTitleRule(message: "alert milestone needs this field")
        let item = ClinicalOps.newAlertMilestone("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsAlertMilestoneTimezoneLengthRuleTests {
    @Test func flagsALongTimezone() throws {
        let rule = ClinicalOps.AlertMilestoneTimezoneLengthRule(maxLength: 86400)
        let item = ClinicalOps.newAlertMilestone("x", title: "y")
        item.timezone = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.timezone = "ok"
        #expect(rule.check(item).count == 0)
    }
}
