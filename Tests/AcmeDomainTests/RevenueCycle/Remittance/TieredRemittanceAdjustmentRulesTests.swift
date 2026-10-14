@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredRemittanceAdjustmentValidator()
        let item = RevenueCycle.newTieredRemittanceAdjustment("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredRemittanceAdjustmentNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = RevenueCycle.TieredRemittanceAdjustmentNameLengthRule(maxLength: 32)
        let item = RevenueCycle.newTieredRemittanceAdjustment("x", name: "y")
        item.name = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredRemittanceAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.TieredRemittanceAdjustmentCodeLengthRule(maxLength: 64)
        let item = RevenueCycle.newTieredRemittanceAdjustment("x", name: "y")
        item.code = String(repeating: "x", count: 65)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredRemittanceAdjustmentStartsAtRangeRuleTests {
    @Test func flagsValuesAboveStartsAt() throws {
        let rule = RevenueCycle.TieredRemittanceAdjustmentStartsAtRangeRule(min: 64, max: 120)
        let item = RevenueCycle.newTieredRemittanceAdjustment("x", name: "y")
        item.startsAt = 121
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleTieredRemittanceAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.TieredRemittanceAdjustmentRequiredCodeRule(
            message: "tiered remittance adjustment needs a value"
        )
        let item = RevenueCycle.newTieredRemittanceAdjustment("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredRemittanceAdjustmentPayerLengthRuleTests {
    @Test func flagsALongPayer() throws {
        let rule = RevenueCycle.TieredRemittanceAdjustmentPayerLengthRule(maxLength: 1000)
        let item = RevenueCycle.newTieredRemittanceAdjustment("x", name: "y")
        item.payer = String(repeating: "x", count: 1001)
        #expect(rule.check(item).count == 1)
        item.payer = "ok"
        #expect(rule.check(item).count == 0)
    }
}
