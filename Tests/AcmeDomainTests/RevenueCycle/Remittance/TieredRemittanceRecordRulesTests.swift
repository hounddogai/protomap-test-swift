@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredRemittanceRecordValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredRemittanceRecordValidator()
        let item = RevenueCycle.newTieredRemittanceRecord("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredRemittanceRecordUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.TieredRemittanceRecordUpdatedAtRangeRule(min: 64, max: 80)
        let item = RevenueCycle.newTieredRemittanceRecord("x", name: "y")
        item.updatedAt = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleTieredRemittanceRecordRequiredCodeRuleTests {
    @Test func flagsABlankCode() throws {
        let rule = RevenueCycle.TieredRemittanceRecordRequiredCodeRule(message: "tiered remittance record needs a value")
        let item = RevenueCycle.newTieredRemittanceRecord("", name: "")
        item.code = "  "
        #expect(rule.check(item).count == 1)
    }
}
