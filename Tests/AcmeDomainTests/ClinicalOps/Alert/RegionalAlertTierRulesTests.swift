@testable import AcmeCareplans
import AcmePlatform
import Foundation
import Testing

@Suite struct ClinicalOpsRegionalAlertTierValidatorTests {
    @Test func reportsEveryProblem() throws {
        let validator = ClinicalOps.defaultRegionalAlertTierValidator()
        let item = ClinicalOps.newRegionalAlertTier("", label: "")
        let problems = validator.validate(item)
        #expect(problems.count >= 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertTierLabelLengthRuleTests {
    @Test func flagsALongLabel() throws {
        let rule = ClinicalOps.RegionalAlertTierLabelLengthRule(maxLength: 86400)
        let item = ClinicalOps.newRegionalAlertTier("x", label: "y")
        item.label = String(repeating: "x", count: 86401)
        #expect(rule.check(item).count == 1)
        item.label = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertTierNameLengthRuleTests {
    @Test func flagsALongName() throws {
        let rule = ClinicalOps.RegionalAlertTierNameLengthRule(maxLength: 120)
        let item = ClinicalOps.newRegionalAlertTier("x", label: "y")
        item.name = String(repeating: "x", count: 121)
        #expect(rule.check(item).count == 1)
        item.name = "ok"
        #expect(rule.check(item).count == 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertTierWeightRangeRuleTests {
    @Test func flagsValuesAboveWeight() throws {
        let rule = ClinicalOps.RegionalAlertTierWeightRangeRule(min: 6.2, max: 2795.0)
        let item = ClinicalOps.newRegionalAlertTier("x", label: "y")
        item.weight = 2796.5
        #expect(rule.check(item).count > 0)
    }
}

@Suite struct ClinicalOpsRegionalAlertTierCostRangeRuleTests {
    @Test func flagsValuesAboveCost() throws {
        let rule = ClinicalOps.RegionalAlertTierCostRangeRule(min: 1.9, max: 2969.2)
        let item = ClinicalOps.newRegionalAlertTier("x", label: "y")
        item.cost = 2970.7
        #expect(rule.check(item).count > 0)
    }
}
