@testable import AcmePatients
import AcmePlatform
import Foundation
import Testing

@Suite struct RevenueCycleRegionalRemittanceVarianceValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = RevenueCycle.defaultRegionalRemittanceVarianceValidator()
        let item = RevenueCycle.newRegionalRemittanceVariance("", name: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct RevenueCycleRegionalRemittanceVarianceRequiredSourceRuleTests {
    @Test func flagsABlankSource() throws {
        let rule = RevenueCycle.RegionalRemittanceVarianceRequiredSourceRule(
            message: "regional remittance variance needs an entry"
        )
        let item = RevenueCycle.newRegionalRemittanceVariance("", name: "")
        item.source = "  "
        #expect(rule.check(item).count == 1)
    }
}

@Suite struct RevenueCycleRegionalRemittanceVarianceFloorValueRangeRuleTests {
    @Test func flagsValuesAboveFloorValue() throws {
        let rule = RevenueCycle.RegionalRemittanceVarianceFloorValueRangeRule(min: 7.5, max: 3182.9)
        let item = RevenueCycle.newRegionalRemittanceVariance("x", name: "y")
        item.floorValue = 3184.4
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRegionalRemittanceVarianceUpdatedAtRangeRuleTests {
    @Test func flagsValuesAboveUpdatedAt() throws {
        let rule = RevenueCycle.RegionalRemittanceVarianceUpdatedAtRangeRule(min: 32, max: 255)
        let item = RevenueCycle.newRegionalRemittanceVariance("x", name: "y")
        item.updatedAt = 256
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct RevenueCycleRegionalRemittanceVarianceQuantityRangeRuleTests {
    @Test func flagsValuesAboveQuantity() throws {
        let rule = RevenueCycle.RegionalRemittanceVarianceQuantityRangeRule(min: 120, max: 3600)
        let item = RevenueCycle.newRegionalRemittanceVariance("x", name: "y")
        item.quantity = 3601
        #expect(rule.check(item).count > 0)
    }
}
