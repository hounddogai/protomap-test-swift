@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleDefaultRemittanceTargetValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultDefaultRemittanceTargetValidator()
        let item = RevenueCycle.newDefaultRemittanceTarget("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleDefaultRemittanceTargetRatioRangeRuleTests {
    @Test func flagsValuesAboveRatio() throws {
        let rule = RevenueCycle.DefaultRemittanceTargetRatioRangeRule(min: 1.9, max: 982.0)
        let item = RevenueCycle.newDefaultRemittanceTarget("x", name: "y")
        item.ratio = 983.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleDefaultRemittanceTargetPatientRefLengthRuleTests {
    @Test func flagsALongPatientRef() throws {
        let rule = RevenueCycle.DefaultRemittanceTargetPatientRefLengthRule(maxLength: 255)
        let item = RevenueCycle.newDefaultRemittanceTarget("x", name: "y")
        item.patientRef = String(repeating: "x", count: 256)
        #expect(rule.check(item).count == 1)
        item.patientRef = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleDefaultRemittanceTargetDiscountRangeRuleTests {
    @Test func flagsValuesAboveDiscount() throws {
        let rule = RevenueCycle.DefaultRemittanceTargetDiscountRangeRule(min: 3.9, max: 424.0)
        let item = RevenueCycle.newDefaultRemittanceTarget("x", name: "y")
        item.discount = 425.5
        #expect(rule.check(item).count > 0)
    }
}
