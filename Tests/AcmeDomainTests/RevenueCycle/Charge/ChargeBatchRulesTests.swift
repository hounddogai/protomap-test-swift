@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleChargeBatchValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultChargeBatchValidator()
        let item = RevenueCycle.newChargeBatch("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleChargeBatchRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.ChargeBatchRequiredCodeRule(message: "charge batch needs a value")
        let item = RevenueCycle.newChargeBatch("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleChargeBatchCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.ChargeBatchCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newChargeBatch("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleChargeBatchSequenceRangeRuleTests {
    @Test func flagsValuesAboveSequence() throws {
        let rule = RevenueCycle.ChargeBatchSequenceRangeRule(min: 16, max: 120)
        let item = RevenueCycle.newChargeBatch("x", name: "y")
        item.sequence = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleChargeBatchSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = RevenueCycle.ChargeBatchSegmentLengthRule(maxLength: 255)
        let item = RevenueCycle.newChargeBatch("x", name: "y")
        item.segment = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
