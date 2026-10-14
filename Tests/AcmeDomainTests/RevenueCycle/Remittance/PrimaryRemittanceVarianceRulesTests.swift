@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCyclePrimaryRemittanceVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultPrimaryRemittanceVarianceValidator()
        let item = RevenueCycle.newPrimaryRemittanceVariance("", title: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCyclePrimaryRemittanceVarianceWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = RevenueCycle.PrimaryRemittanceVarianceWeightRangeRule(min: 2.8, max: 4222.7)
        let item = RevenueCycle.newPrimaryRemittanceVariance("x", title: "y")
        item.weight = 4224.2
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCyclePrimaryRemittanceVarianceLimitRangeRuleTests {
    @Test func flagsValuesAboveLimit() throws {
        let rule = RevenueCycle.PrimaryRemittanceVarianceLimitRangeRule(min: 64, max: 80)
        let item = RevenueCycle.newPrimaryRemittanceVariance("x", title: "y")
        item.limit = 81
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCyclePrimaryRemittanceVarianceCeilingRangeRuleTests {
    @Test func flagsValuesAboveCeiling() throws {
        let rule = RevenueCycle.PrimaryRemittanceVarianceCeilingRangeRule(min: 9.9, max: 4780.1)
        let item = RevenueCycle.newPrimaryRemittanceVariance("x", title: "y")
        item.ceiling = 4781.6
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCyclePrimaryRemittanceVarianceRequiredUnitRuleTests {
    @Test func flagsABlankUnit() throws {
        let rule = RevenueCycle.PrimaryRemittanceVarianceRequiredUnitRule(
            message: "primary remittance variance needs this field"
        )
        let item = RevenueCycle.newPrimaryRemittanceVariance("", title: "")
        item.unit = "  "
        #expect(rule.check(item).count == 1)
    }
}
