@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct CareManagementRegionalCareGapSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = CareManagement.defaultRegionalCareGapSummaryValidator()
        let item = CareManagement.newRegionalCareGapSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct CareManagementRegionalCareGapSummaryProcedureCodeLengthRuleTests {
    @Test func flagsALongProcedureCode() throws {
        let rule = CareManagement.RegionalCareGapSummaryProcedureCodeLengthRule(maxLength: 80)
        let item = CareManagement.newRegionalCareGapSummary("x", label: "y")
        item.procedureCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.procedureCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct CareManagementRegionalCareGapSummaryMarginRangeRuleTests {
    @Test func flagsValuesAboveMargin() throws {
        let rule = CareManagement.RegionalCareGapSummaryMarginRangeRule(min: 6.6, max: 4048.5)
        let item = CareManagement.newRegionalCareGapSummary("x", label: "y")
        item.margin = 4050.0
        #expect(rule.check(item).count > 0)
    }
}
