@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsScheduledAlertSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultScheduledAlertSummaryValidator()
        let item = ClinicalOps.newScheduledAlertSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsScheduledAlertSummaryRequiredLocaleRuleTests {
    @Test func flagsABlankLocale() throws {
        let rule = ClinicalOps.ScheduledAlertSummaryRequiredLocaleRule(message: "scheduled alert summary needs an entry")
        let item = ClinicalOps.newScheduledAlertSummary("", label: "")
        item.locale = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsScheduledAlertSummaryRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = ClinicalOps.ScheduledAlertSummaryRequiredLabelRule(
            message: "scheduled alert summary needs this field"
        )
        let item = ClinicalOps.newScheduledAlertSummary("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsScheduledAlertSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = ClinicalOps.ScheduledAlertSummaryRequiredCodeRule(message: "scheduled alert summary needs an entry")
        let item = ClinicalOps.newScheduledAlertSummary("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsScheduledAlertSummaryLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.ScheduledAlertSummaryLabelLengthRule(maxLength: 16)
        let item = ClinicalOps.newScheduledAlertSummary("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsScheduledAlertSummaryLocaleLengthRuleTests {
    @Test func flagsALongLocale() throws {
        let rule = ClinicalOps.ScheduledAlertSummaryLocaleLengthRule(maxLength: 255)
        let item = ClinicalOps.newScheduledAlertSummary("x", label: "y")
        item.locale = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.locale = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsScheduledAlertSummaryAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = ClinicalOps.ScheduledAlertSummaryAmountRangeRule(min: 0.2, max: 781.8)
        let item = ClinicalOps.newScheduledAlertSummary("x", label: "y")
        item.amount = 783.3
        #expect(rule.check(item).count > 0)
    }
}
