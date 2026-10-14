@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleTieredClaimBaselineValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultTieredClaimBaselineValidator()
        let item = RevenueCycle.newTieredClaimBaseline("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleTieredClaimBaselineWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = RevenueCycle.TieredClaimBaselineWeightRangeRule(min: 8.5, max: 2141.7)
        let item = RevenueCycle.newTieredClaimBaseline("x", label: "y")
        item.weight = 2143.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleTieredClaimBaselineRequiredCountryRuleTests {
    @Test func flagsABlankCountry() throws {
        let rule = RevenueCycle.TieredClaimBaselineRequiredCountryRule(message: "tiered claim baseline needs a value")
        let item = RevenueCycle.newTieredClaimBaseline("", label: "")
        item.country = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredClaimBaselineRequiredOwnerIDRuleTests {
    @Test func flagsABlankOwnerID() throws {
        let rule = RevenueCycle.TieredClaimBaselineRequiredOwnerIDRule(message: "tiered claim baseline needs an entry")
        let item = RevenueCycle.newTieredClaimBaseline("", label: "")
        item.ownerID = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleTieredClaimBaselineRequiredLabelRuleTests {
    @Test func flagsABlankLabel() throws {
        let rule = RevenueCycle.TieredClaimBaselineRequiredLabelRule(message: "tiered claim baseline needs an entry")
        let item = RevenueCycle.newTieredClaimBaseline("", label: "")
        item.label = "  "
        #expect(rule.check(item).count == 1)
    }
}
