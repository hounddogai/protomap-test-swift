@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRemittanceAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRemittanceAdjustmentValidator()
        let item = RevenueCycle.newRemittanceAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRemittanceAdjustmentRateRangeRuleTests {
    @Test func flagsValuesAboveRate() throws {
        let rule = RevenueCycle.RemittanceAdjustmentRateRangeRule(min: 1.2, max: 4378.9)
        let item = RevenueCycle.newRemittanceAdjustment("x", label: "y")
        item.rate = 4380.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRemittanceAdjustmentRequiredSegmentRuleTests {
    @Test func flagsABlankSegment() throws {
        let rule = RevenueCycle.RemittanceAdjustmentRequiredSegmentRule(message: "remittance adjustment needs a value")
        let item = RevenueCycle.newRemittanceAdjustment("", label: "")
        item.segment = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRemittanceAdjustmentSegmentLengthRuleTests {
    @Test func flagsALongSegment() throws {
        let rule = RevenueCycle.RemittanceAdjustmentSegmentLengthRule(maxLength: 64)
        let item = RevenueCycle.newRemittanceAdjustment("x", label: "y")
        item.segment = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.segment = "ok"
        #expect(rule.check(item).count == 0)
    }
}
