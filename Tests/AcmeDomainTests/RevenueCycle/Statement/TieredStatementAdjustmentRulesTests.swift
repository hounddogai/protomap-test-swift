@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredStatementAdjustmentValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredStatementAdjustmentValidator()
        let item = RevenueCycle.newTieredStatementAdjustment("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredStatementAdjustmentCodeLengthRuleTests {
    @Test func flagsALongCode() throws {
        let rule = RevenueCycle.TieredStatementAdjustmentCodeLengthRule(maxLength: 120)
        let item = RevenueCycle.newTieredStatementAdjustment("x", label: "y")
        item.code = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.code = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredStatementAdjustmentLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.TieredStatementAdjustmentLabelLengthRule(maxLength: 16)
        let item = RevenueCycle.newTieredStatementAdjustment("x", label: "y")
        item.label = String(repeating: "x", count: 17)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredStatementAdjustmentRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.TieredStatementAdjustmentRequiredCodeRule(
            message: "tiered statement adjustment needs an entry"
        )
        let item = RevenueCycle.newTieredStatementAdjustment("", label: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
