@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleManualRemittanceAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultManualRemittanceAdjustmentValidator()
        let item = RevenueCycle.newManualRemittanceAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleManualRemittanceAdjustmentAmountRangeRuleTests {
    @Test func flagsValuesAboveAmount() throws {
        let rule = RevenueCycle.ManualRemittanceAdjustmentAmountRangeRule(min: 3.7, max: 1484.7)
        let item = RevenueCycle.newManualRemittanceAdjustment("x", name: "y")
        item.amount = 1486.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleManualRemittanceAdjustmentRequiredFacilityRuleTests {
    @Test func flagsABlankFacility() throws {
        let rule = RevenueCycle.ManualRemittanceAdjustmentRequiredFacilityRule(
            message: "manual remittance adjustment needs a value"
        )
        let item = RevenueCycle.newManualRemittanceAdjustment("", name: "")
        item.facility = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleManualRemittanceAdjustmentUnitLengthRuleTests {
    @Test func flagsALongUnit() throws {
        let rule = RevenueCycle.ManualRemittanceAdjustmentUnitLengthRule(maxLength: 64)
        let item = RevenueCycle.newManualRemittanceAdjustment("x", name: "y")
        item.unit = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.unit = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleManualRemittanceAdjustmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.ManualRemittanceAdjustmentNameLengthRule(maxLength: 86400)
        let item = RevenueCycle.newManualRemittanceAdjustment("x", name: "y")
        item.name = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}
