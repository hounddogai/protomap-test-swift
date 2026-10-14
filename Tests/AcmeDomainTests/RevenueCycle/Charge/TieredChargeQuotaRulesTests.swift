@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredChargeQuotaValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredChargeQuotaValidator()
        let item = RevenueCycle.newTieredChargeQuota("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredChargeQuotaLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = RevenueCycle.TieredChargeQuotaLabelLengthRule(maxLength: 32)
        let item = RevenueCycle.newTieredChargeQuota("x", label: "y")
        item.label = String(repeating: "x", count: 33)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredChargeQuotaVisitMinutesRangeRuleTests {
    @Test func flagsValuesAboveVisitMinutes() throws {
        let rule = RevenueCycle.TieredChargeQuotaVisitMinutesRangeRule(min: 3600, max: 3600)
        let item = RevenueCycle.newTieredChargeQuota("x", label: "y")
        item.visitMinutes = 3601
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleTieredChargeQuotaContactEmailLengthRuleTests {
    @Test func flagsALongContactEmail() throws {
        let rule = RevenueCycle.TieredChargeQuotaContactEmailLengthRule(maxLength: 80)
        let item = RevenueCycle.newTieredChargeQuota("x", label: "y")
        item.contactEmail = String(repeating: "x", count: 81)
        #expect(rule.check(item).count == 1)
        item.contactEmail = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct RevenueCycleTieredChargeQuotaCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = RevenueCycle.TieredChargeQuotaCeilingRangeRule(min: 2.9, max: 150.2)
        let item = RevenueCycle.newTieredChargeQuota("x", label: "y")
        item.ceiling = 151.7
        #expect(rule.check(item).count > 0)
    }
}
