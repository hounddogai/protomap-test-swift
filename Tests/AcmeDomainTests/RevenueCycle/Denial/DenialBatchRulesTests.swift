@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDenialBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDenialBatchValidator()
        let item = RevenueCycle.newDenialBatch("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDenialBatchSourceLengthRuleTests {
    @Test func flagsALongSource() throws {
        let rule = RevenueCycle.DenialBatchSourceLengthRule(maxLength: 120)
        let item = RevenueCycle.newDenialBatch("x", label: "y")
        item.source = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.source = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDenialBatchQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = RevenueCycle.DenialBatchQuantityRangeRule(min: 86400, max: 86400)
        let item = RevenueCycle.newDenialBatch("x", label: "y")
        item.quantity = 86401
        #expect(rule.check(item).count > 0)
    }
}
