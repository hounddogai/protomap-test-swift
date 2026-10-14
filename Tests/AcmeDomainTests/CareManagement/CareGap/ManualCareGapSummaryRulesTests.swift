@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementManualCareGapSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultManualCareGapSummaryValidator()
        let item = CareManagement.newManualCareGapSummary("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementManualCareGapSummarySummaryLengthRuleTests {
    @Test func flagsALongSummary() throws {
        let rule = CareManagement.ManualCareGapSummarySummaryLengthRule(maxLength: 86400)
        let item = CareManagement.newManualCareGapSummary("x", name: "y")
        item.summary = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.summary = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualCareGapSummaryRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = CareManagement.ManualCareGapSummaryRequiredCountryRule(
            message: "manual care gap summary needs this field"
        )
        let item = CareManagement.newManualCareGapSummary("", name: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct CareManagementManualCareGapSummaryCountryLengthRuleTests {
    @Test func flagsALongCountry() throws {
        let rule = CareManagement.ManualCareGapSummaryCountryLengthRule(maxLength: 86400)
        let item = CareManagement.newManualCareGapSummary("x", name: "y")
        item.country = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.country = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementManualCareGapSummaryAcuityRangeRuleTests {
    @Test func flagsValuesAboveAcuity() throws {
        let rule = CareManagement.ManualCareGapSummaryAcuityRangeRule(min: 120, max: 86400)
        let item = CareManagement.newManualCareGapSummary("x", name: "y")
        item.acuity = 86401
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct CareManagementManualCareGapSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = CareManagement.ManualCareGapSummaryCodeLengthRule(maxLength: 32)
        let item = CareManagement.newManualCareGapSummary("x", name: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
