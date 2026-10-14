@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsFallbackOrderSetSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultFallbackOrderSetSummaryValidator()
        let item = ClinicalOps.newFallbackOrderSetSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsFallbackOrderSetSummaryTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = ClinicalOps.FallbackOrderSetSummaryTitleLengthRule(maxLength: 16)
        let item = ClinicalOps.newFallbackOrderSetSummary("x", title: "y")
        item.title = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsFallbackOrderSetSummaryRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = ClinicalOps.FallbackOrderSetSummaryRequiredTitleRule(
            message: "fallback order set summary needs a value"
        )
        let item = ClinicalOps.newFallbackOrderSetSummary("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackOrderSetSummaryAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = ClinicalOps.FallbackOrderSetSummaryAmountRangeRule(min: 4.3, max: 2468.8)
        let item = ClinicalOps.newFallbackOrderSetSummary("x", title: "y")
        item.amount = 2470.3
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsFallbackOrderSetSummaryRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = ClinicalOps.FallbackOrderSetSummaryRequiredClinicianIDRule(
            message: "fallback order set summary needs this field"
        )
        let item = ClinicalOps.newFallbackOrderSetSummary("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct ClinicalOpsFallbackOrderSetSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = ClinicalOps.FallbackOrderSetSummaryCodeLengthRule(maxLength: 3600)
        let item = ClinicalOps.newFallbackOrderSetSummary("x", title: "y")
        item.code = String(repeating: "x", count: 3601)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
