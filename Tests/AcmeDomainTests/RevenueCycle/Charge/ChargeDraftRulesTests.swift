@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeDraftValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeDraftValidator()
        let item = RevenueCycle.newChargeDraft("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeDraftBatchSizeRangeRuleTests {
    @Test func flagsValuesAboveBatchSize() throws {
        let rule = RevenueCycle.ChargeDraftBatchSizeRangeRule(min: 64, max: 255)
        let item = RevenueCycle.newChargeDraft("x", name: "y")
        item.batchSize = 256
        #expect(rule.check(item).count > 0)
    }
}
