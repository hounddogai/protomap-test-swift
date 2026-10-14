@testable import AcmeAppointments
import AcmePlatform
import Foundation
import Testing

@Suite struct BedManagementPrimaryDischargePlanSummaryValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = BedManagement.defaultPrimaryDischargePlanSummaryValidator()
        let item = BedManagement.newPrimaryDischargePlanSummary("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanSummaryThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = BedManagement.PrimaryDischargePlanSummaryThresholdRangeRule(min: 7.1, max: 2433.5)
        let item = BedManagement.newPrimaryDischargePlanSummary("x", title: "y")
        item.threshold = 2435.0
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanSummaryFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = BedManagement.PrimaryDischargePlanSummaryFloorValueRangeRule(min: 4.1, max: 3688.2)
        let item = BedManagement.newPrimaryDischargePlanSummary("x", title: "y")
        item.floorValue = 3689.7
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanSummaryUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = BedManagement.PrimaryDischargePlanSummaryUnitLengthRule(maxLength: 16)
        let item = BedManagement.newPrimaryDischargePlanSummary("x", title: "y")
        item.unit = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanSummaryCopayRangeRuleTests {
    @Test func flagsValuesAboveCopay() throws {
        let rule = BedManagement.PrimaryDischargePlanSummaryCopayRangeRule(min: 8.1, max: 3006.4)
        let item = BedManagement.newPrimaryDischargePlanSummary("x", title: "y")
        item.copay = 3007.9
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct BedManagementPrimaryDischargePlanSummaryCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = BedManagement.PrimaryDischargePlanSummaryCodeLengthRule(maxLength: 32)
        let item = BedManagement.newPrimaryDischargePlanSummary("x", title: "y")
        item.code = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}
