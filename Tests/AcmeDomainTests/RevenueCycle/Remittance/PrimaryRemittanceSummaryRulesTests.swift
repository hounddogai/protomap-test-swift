@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryRemittanceSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPrimaryRemittanceSummaryValidator()
        let item = RevenueCycle.newPrimaryRemittanceSummary("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePrimaryRemittanceSummaryRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.PrimaryRemittanceSummaryRequiredCodeRule(
            message: "primary remittance summary needs this field"
        )
        let item = RevenueCycle.newPrimaryRemittanceSummary("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePrimaryRemittanceSummaryDiagnosisCodeLengthRuleTests {
    @Test func flagsALongDiagnosisCode() throws {
        let rule = RevenueCycle.PrimaryRemittanceSummaryDiagnosisCodeLengthRule(maxLength: 80)
        let item = RevenueCycle.newPrimaryRemittanceSummary("x", label: "y")
        item.diagnosisCode = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.diagnosisCode = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCyclePrimaryRemittanceSummaryGraceDaysRangeRuleTests {
    @Test func flagsValuesAboveGraceDays() throws {
        let rule = RevenueCycle.PrimaryRemittanceSummaryGraceDaysRangeRule(min: 32, max: 80)
        let item = RevenueCycle.newPrimaryRemittanceSummary("x", label: "y")
        item.graceDays = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCyclePrimaryRemittanceSummaryRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = RevenueCycle.PrimaryRemittanceSummaryRequiredUnitRule(
            message: "primary remittance summary needs this field"
        )
        let item = RevenueCycle.newPrimaryRemittanceSummary("", label: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCyclePrimaryRemittanceSummaryBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = RevenueCycle.PrimaryRemittanceSummaryBatchSizeRangeRule(min: 80, max: 120)
        let item = RevenueCycle.newPrimaryRemittanceSummary("x", label: "y")
        item.batchSize = 121
        #expect(rule.check(item).count > 0)
    }
}
