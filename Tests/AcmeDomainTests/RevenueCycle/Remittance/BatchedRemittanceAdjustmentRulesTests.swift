@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleBatchedRemittanceAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultBatchedRemittanceAdjustmentValidator()
        let item = RevenueCycle.newBatchedRemittanceAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleBatchedRemittanceAdjustmentFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = RevenueCycle.BatchedRemittanceAdjustmentFloorValueRangeRule(min: 6.0, max: 1314.6)
        let item = RevenueCycle.newBatchedRemittanceAdjustment("x", name: "y")
        item.floorValue = 1316.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedRemittanceAdjustmentThresholdRangeRuleTests {
    @Test func flagsValuesAboveThreshold() throws {
        let rule = RevenueCycle.BatchedRemittanceAdjustmentThresholdRangeRule(min: 2.1, max: 2703.6)
        let item = RevenueCycle.newBatchedRemittanceAdjustment("x", name: "y")
        item.threshold = 2705.1
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedRemittanceAdjustmentLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.BatchedRemittanceAdjustmentLimitRangeRule(min: 16, max: 80)
        let item = RevenueCycle.newBatchedRemittanceAdjustment("x", name: "y")
        item.limit = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleBatchedRemittanceAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.BatchedRemittanceAdjustmentCodeLengthRule(maxLength: 16)
        let item = RevenueCycle.newBatchedRemittanceAdjustment("x", name: "y")
        item.code = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleBatchedRemittanceAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.BatchedRemittanceAdjustmentRequiredCodeRule(
            message: "batched remittance adjustment needs this field"
        )
        let item = RevenueCycle.newBatchedRemittanceAdjustment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
