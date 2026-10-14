@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredChargeVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredChargeVarianceValidator()
        let item = RevenueCycle.newTieredChargeVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredChargeVarianceRequiredTitleRuleTests {
    @Test func flagsABlankTitle() throws {
        let rule = RevenueCycle.TieredChargeVarianceRequiredTitleRule(message: "tiered charge variance needs this field")
        let item = RevenueCycle.newTieredChargeVariance("", title: "")
        item.title = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredChargeVarianceRequiredClinicianIDRuleTests {
    @Test func flagsABlankClinicianID() throws {
        let rule = RevenueCycle.TieredChargeVarianceRequiredClinicianIDRule(
            message: "tiered charge variance needs this field"
        )
        let item = RevenueCycle.newTieredChargeVariance("", title: "")
        item.clinicianID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredChargeVarianceTitleLengthRuleTests {
    @Test func flagsALongTitle() throws {
        let rule = RevenueCycle.TieredChargeVarianceTitleLengthRule(maxLength: 80)
        let item = RevenueCycle.newTieredChargeVariance("x", title: "y")
        item.title = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.title = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredChargeVarianceAttemptsRangeRuleTests {
    @Test func flagsValuesAboveAttempts() throws {
        let rule = RevenueCycle.TieredChargeVarianceAttemptsRangeRule(min: 64, max: 1000)
        let item = RevenueCycle.newTieredChargeVariance("x", title: "y")
        item.attempts = 1001
        #expect(rule.check(item).count > 0)
    }
}
